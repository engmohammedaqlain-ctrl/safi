import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bootstrap/prefs_keys.dart';
import '../bootstrap/startup_ledger_data.dart';
import '../auth/firestore_registered_phone_auth.dart';
import 'ledger_json_merge.dart';
import '../../features/cash_flow/providers/accounts_provider.dart';
import '../../features/debts/providers/debt_categories_provider.dart';
import '../../features/debts/providers/debts_ui_provider.dart';
import '../../features/sales/models/cashbook_entry.dart';
import '../../features/sales/providers/cashbook_ui_provider.dart';

/// سحب تدفق حالة المصادقة (مستخدم واحد أو null).
final firebaseAuthStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

/// حالة واجهة المزامنة: تعديل محلي بانتظار الرفع، أو آخر خطأ من السحابة.
class LedgerSyncUiState {
  const LedgerSyncUiState({
    this.needsCloudPush = false,
    this.lastPushError,
  });

  final bool needsCloudPush;
  final String? lastPushError;
}

class LedgerSyncUiNotifier extends Notifier<LedgerSyncUiState> {
  @override
  LedgerSyncUiState build() => const LedgerSyncUiState();

  void markLocalChanged() {
    state = LedgerSyncUiState(
      needsCloudPush: true,
      lastPushError: state.lastPushError,
    );
  }

  void markPushSucceeded() => state = const LedgerSyncUiState();

  void markPushFailed(String? message) {
    state = LedgerSyncUiState(needsCloudPush: true, lastPushError: message);
  }

  void reset() => state = const LedgerSyncUiState();
}

final ledgerSyncUiProvider =
    NotifierProvider<LedgerSyncUiNotifier, LedgerSyncUiState>(
  LedgerSyncUiNotifier.new,
);

/// مزامنة الحافظة مع Firestore بنسخة **V2**:
/// - مجموعات فرعية تحت **`users/{uid}`**: `debtors`, `transactions`, `cashbook`, `accounts`, `debt_categories`
/// - مستخدم المستند `users/{uid}` يعرِّف `ledgerSchemaV` وحقلي اختبار للاسم ورقم المتجر المحلي
/// - يُستورد تلقائياً مستند الوضع **`users/{uid}/safi/ledger_state`** إن كان قديماً
///
/// **قواعد المقترحة:** `match /users/{uid}/{document=**} { allow read, write: if request.auth.uid == uid; }`
class LedgerFirestoreSync {
  LedgerFirestoreSync(this._ref);

  final Ref _ref;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Timer? _debouncePush;
  Timer? _debounceInboundUi;
  String? _connectedUid;

  void bindPersistHook() {
    StartupLedgerData.onLedgerPersistedForCloud = schedulePushDebounced;
  }

  void unbindPersistHook() {
    if (StartupLedgerData.onLedgerPersistedForCloud == schedulePushDebounced) {
      StartupLedgerData.onLedgerPersistedForCloud = null;
    }
  }

  void schedulePushDebounced() {
    try {
      _ref.read(ledgerSyncUiProvider.notifier).markLocalChanged();
    } catch (_) {}
    _debouncePush?.cancel();
    _debouncePush = Timer(const Duration(milliseconds: 900), () async {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirestoreRegisteredPhoneAuth.trySilentReauthFromPrefs();
      }
      final prefs = await SharedPreferences.getInstance();
      final targetUid = prefs.getString(PrefsKeys.ledgerOwnerUid) ?? FirebaseAuth.instance.currentUser?.uid;
      if (targetUid == null) return;
      unawaited(pushNow(targetUid));
    });
  }

  DocumentReference<Map<String, dynamic>> _userDocRef(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<void> attachIfNeeded(String uid) async {
    if (_connectedUid == uid && _subscriptions.isNotEmpty) return;
    await detach();

    _connectedUid = uid;

    await _migrateLegacyLedgerStateIfNeeded(uid);
    await _tryMergeLedgerFromServer(uid);
    await _subscribeAll(uid);
    unawaited(pushNow(uid));
  }

  /// أول مزامنة من السيرفر (وليس من الكاش فقط) ثم دمجها في التخزين المحلي — يُفضّلها عند الدخول والاتصال.
  Future<void> _tryMergeLedgerFromServer(String uid) async {
    final ud = _userDocRef(uid);
    const server = GetOptions(source: Source.server);
    try {
      await ud.get(server);

      Future<void> pullAndMerge(
        String sub,
        Future<void> Function(List<Map<String, dynamic>> maps) merge,
      ) async {
        final snap = await ud.collection(sub).get(server);
        final maps = <Map<String, dynamic>>[
          for (final d in snap.docs) Map<String, dynamic>.from(d.data()),
        ];
        await merge(maps);
      }

      await pullAndMerge('debtors', _mergeDebtorsPrefs);
      await pullAndMerge('transactions', _mergeTxnPrefs);
      await pullAndMerge('cashbook', _mergeCashPrefs);
      await pullAndMerge('accounts', _mergeAccPrefs);
      await pullAndMerge('debt_categories', _mergeCatPrefs);

      await StartupLedgerData.reloadFromDiskIntoMemory();
      _ref.invalidate(debtorsUiProvider);
      _ref.invalidate(transactionsProvider);
      _ref.invalidate(cashbookEntriesProvider);
      _ref.invalidate(accountsProvider);
      _ref.invalidate(debtCategoriesProvider);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' ||
          e.code == 'deadline-exceeded' ||
          e.code == 'network-request-failed') {
        debugPrint('LedgerFirestoreSync: سحب السيرفر غير متاح (شبكة): $e');
        return;
      }
      debugPrint('LedgerFirestoreSync: سحب السيرفر فشل: $e');
    } catch (e, st) {
      debugPrint('LedgerFirestoreSync: سحب السيرفر $e\n$st');
    }
  }

  /// يستورد `users/{uid}/safi/ledger_state` مرّة إن لم تُكمَّل ترقية [ledgerSchemaV].
  Future<void> _migrateLegacyLedgerStateIfNeeded(String uid) async {
    final ud = _userDocRef(uid);
    final snap = await ud.get(const GetOptions(source: Source.serverAndCache));
    if (((snap.data() ?? {})['ledgerSchemaV'] ?? 0) as int >= 2) return;

    final legacy = await ud
        .collection('safi')
        .doc('ledger_state')
        .get();

    if (!legacy.exists || legacy.data() == null) {
      await ud.set(
        {
          'ledgerSchemaV': 2,
          if (FirebaseAuth.instance.currentUser?.displayName != null)
            'firebaseDisplayHint': FirebaseAuth.instance.currentUser!.displayName,
        },
        SetOptions(merge: true),
      );
      return;
    }

    final raw = legacy.data()!;
    var batch = _firestore.batch();
    var n = 0;

    void writeArray(String jsonKey, String subName) {
      final js = raw[jsonKey] as String?;
      if (js == null || js.isEmpty || js == '[]') return;
      List<dynamic> list;
      try {
        list = jsonDecode(js) as List<dynamic>;
      } catch (_) {
        return;
      }
      final col = ud.collection(subName);
      for (final e in list) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final docId = m['id']?.toString();
        if (docId == null || docId.isEmpty) continue;
        batch.set(col.doc(docId), m, SetOptions(merge: true));
        n++;
        if (n >= 380) {
          unawaited(batch.commit());
          batch = _firestore.batch();
          n = 0;
        }
      }
    }

    writeArray('debtors_json', 'debtors');
    writeArray('transactions_json', 'transactions');
    writeArray('cashbook_json', 'cashbook');
    writeArray('accounts_json', 'accounts');
    writeArray('debt_categories_json', 'debt_categories');

    await batch.commit();
    await legacy.reference.set({'legacyArchived': true}, SetOptions(merge: true));

    await ud.set(
      {
        'ledgerSchemaV': 2,
        'ledgerMigratedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _subscribeAll(String uid) async {
    final ud = _userDocRef(uid);

    void pipe(
      Query<Map<String, dynamic>> q,
      Future<void> Function(List<Map<String, dynamic>> docs) merger,
    ) {
      final sub = q.snapshots(includeMetadataChanges: false).listen(
        (snap) {
          if (snap.metadata.hasPendingWrites) return;
          unawaited(merger(_docsMaps(snap)));
          _debounceInboundUi?.cancel();
          _debounceInboundUi = Timer(
            const Duration(milliseconds: 280),
            () {
              unawaited(_reloadAndInvalidate(uid));
            },
          );
        },
        onError: (Object e, StackTrace st) {
          debugPrint('LedgerFirestoreSync listen: $e\n$st');
        },
      );
      _subscriptions.add(sub);
    }

    pipe(ud.collection('debtors'), (docs) async {
      await _mergeDebtorsPrefs(docs);
    });
    pipe(ud.collection('transactions'), (docs) async {
      await _mergeTxnPrefs(docs);
    });
    pipe(ud.collection('cashbook'), (docs) async {
      await _mergeCashPrefs(docs);
    });
    pipe(ud.collection('accounts'), (docs) async {
      await _mergeAccPrefs(docs);
    });
    pipe(ud.collection('debt_categories'), (docs) async {
      await _mergeCatPrefs(docs);
    });
  }

  List<Map<String, dynamic>> _docsMaps(QuerySnapshot<Map<String, dynamic>> s) {
    return [
      for (final d in s.docs) Map<String, dynamic>.from(d.data()),
    ];
  }

  Future<void> _mergeDebtorsPrefs(List<Map<String, dynamic>> maps) async {
    final remote = StartupLedgerData.encodeDebtorsJson([
      for (final m in maps) StartupLedgerData.debtorFromMap(m),
    ]);
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString(PrefsKeys.debtors) ?? '[]';
    final merged = LedgerJsonMerge.mergeDebtors(remote, local);
    await prefs.setString(PrefsKeys.debtors, merged);
    await _bumpTrackedMs(prefs);
  }

  Future<void> _mergeTxnPrefs(List<Map<String, dynamic>> maps) async {
    final remote = StartupLedgerData.encodeTransactionsJson([
      for (final m in maps) StartupLedgerData.transactionFromMap(m),
    ]);
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString(PrefsKeys.transactions) ?? '[]';
    await prefs.setString(
      PrefsKeys.transactions,
      LedgerJsonMerge.mergeTransactions(remote, local),
    );
    await _bumpTrackedMs(prefs);
  }

  Future<void> _mergeCashPrefs(List<Map<String, dynamic>> maps) async {
    final remote = StartupLedgerData.encodeCashbookJson([
      for (final m in maps)
        CashbookEntry.fromJson(Map<String, dynamic>.from(m)),
    ]);
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString(PrefsKeys.cashbook) ?? '[]';
    await prefs.setString(
      PrefsKeys.cashbook,
      LedgerJsonMerge.mergeCashbook(remote, local),
    );
    await _bumpTrackedMs(prefs);
  }

  Future<void> _mergeAccPrefs(List<Map<String, dynamic>> maps) async {
    final remote = StartupLedgerData.encodeAccountsJson([
      for (final m in maps) StartupLedgerData.financialAccountFromMap(m),
    ]);
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString(PrefsKeys.accounts) ?? '[]';
    final merged = LedgerJsonMerge.mergeAccounts(remote, local);
    await prefs.setString(
      PrefsKeys.accounts,
      StartupLedgerData.migrateLegacyAccountNamesInAccountsJson(merged),
    );
    await _bumpTrackedMs(prefs);
  }

  Future<void> _mergeCatPrefs(List<Map<String, dynamic>> maps) async {
    final remote = StartupLedgerData.encodeDebtCategoriesJson([
      for (final m in maps) StartupLedgerData.debtCategoryFromMap(m),
    ]);
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getString(PrefsKeys.debtCategories) ?? '[]';
    await prefs.setString(
      PrefsKeys.debtCategories,
      LedgerJsonMerge.mergeDebtCategories(remote, local),
    );
    await _bumpTrackedMs(prefs);
  }

  Future<void> _bumpTrackedMs(SharedPreferences prefs) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final prev = prefs.getInt(PrefsKeys.lastLedgerSyncedMs) ?? 0;
    await prefs.setInt(
      PrefsKeys.lastLedgerSyncedMs,
      ts > prev ? ts : prev,
    );
  }

  Future<void> _reloadAndInvalidate(String uid) async {
    await StartupLedgerData.reloadFromDiskIntoMemory();
    _ref.invalidate(debtorsUiProvider);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(cashbookEntriesProvider);
    _ref.invalidate(accountsProvider);
    _ref.invalidate(debtCategoriesProvider);
  }

  Future<void> detach() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
    _debouncePush?.cancel();
    _debouncePush = null;
    _debounceInboundUi?.cancel();
    _debounceInboundUi = null;
    _connectedUid = null;
  }

  /// يحذف كل وثائق الدفتر والفريق ومساعد الدردشة تحت `users/{ownerUid}`،
  /// ودعوات الفريق على `team_invites`، ويزيل اسم المتجر من `registered_phones` إن وُجد.
  /// يُعيد `true` عند اكتمال العملية، أو `false` عند خطأ شبكة/صلاحيات.
  Future<bool> wipeOwnerLedgerCloudAndRelated({
    required String ownerUid,
    String? registeredPhoneDocId,
  }) async {
    final ud = _userDocRef(ownerUid);

    Future<void> wipeSub(String name) async {
      final col = ud.collection(name);
      while (true) {
        final snap = await col.limit(400).get();
        if (snap.docs.isEmpty) break;
        var batch = _firestore.batch();
        var n = 0;
        for (final d in snap.docs) {
          batch.delete(d.reference);
          n++;
          if (n >= 400) {
            await batch.commit();
            batch = _firestore.batch();
            n = 0;
          }
        }
        if (n > 0) await batch.commit();
      }
    }

    try {
      await Future.wait([
        wipeSub('debtors'),
        wipeSub('transactions'),
        wipeSub('cashbook'),
        wipeSub('accounts'),
        wipeSub('debt_categories'),
        wipeSub('team'),
        wipeSub('ledger_access'),
        wipeSub('ai_history'),
      ]);

      try {
        await ud.collection('safi').doc('ledger_state').delete();
      } catch (_) {}

      final invites = await _firestore
          .collection('team_invites')
          .where('ownerUid', isEqualTo: ownerUid)
          .get();
      if (invites.docs.isNotEmpty) {
        var batch = _firestore.batch();
        var n = 0;
        for (final d in invites.docs) {
          batch.delete(d.reference);
          n++;
          if (n >= 400) {
            await batch.commit();
            batch = _firestore.batch();
            n = 0;
          }
        }
        if (n > 0) await batch.commit();
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await ud.set(
        {
          'ledgerSchemaV': 2,
          'ledgerUpdatedMs': nowMs,
          'storeDisplayHint': FieldValue.delete(),
          'registeredPhoneHint': FieldValue.delete(),
          'ledgerMigratedAt': FieldValue.delete(),
          'firebaseDisplayHint': FieldValue.delete(),
        },
        SetOptions(merge: true),
      );

      if (registeredPhoneDocId != null && registeredPhoneDocId.isNotEmpty) {
        await _firestore.collection('registered_phones').doc(registeredPhoneDocId).set(
              {'displayName': FieldValue.delete()},
              SetOptions(merge: true),
            );
      }

      return true;
    } on FirebaseException catch (e, st) {
      debugPrint('wipeOwnerLedgerCloudAndRelated: $e\n$st');
      return false;
    } catch (e, st) {
      debugPrint('wipeOwnerLedgerCloudAndRelated: $e\n$st');
      return false;
    }
  }

  /// يُعيد [true] عند اكتمال الرفع وتحديث الطابع المحلي، أو [false] عند الفشل.
  Future<bool> pushNow(String uid) async {
    final ud = _userDocRef(uid);
    final prefs = await SharedPreferences.getInstance();

    Future<void> pushDocList({
      required String prefsKey,
      required String subcollection,
      required List<Map<String, dynamic>> Function(String raw) toDocMaps,
    }) async {
      final raw = prefs.getString(prefsKey) ?? '[]';
      final docs = toDocMaps(raw);
      var batch = _firestore.batch();
      var ops = 0;
      final col = ud.collection(subcollection);
      for (final m in docs) {
        final id = m['id']?.toString();
        if (id == null || id.isEmpty) continue;
        
        if (m['isDeleted'] == true) {
          batch.delete(col.doc(id));
        } else {
          batch.set(col.doc(id), m, SetOptions(merge: true));
        }
        ops++;
        if (ops >= 400) {
          await batch.commit();
          batch = _firestore.batch();
          ops = 0;
        }
      }
      if (ops > 0) await batch.commit();
    }

    List<Map<String, dynamic>> mapDebtors(String raw) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return [
          for (final e in list)
            if (e is Map)
              StartupLedgerData.debtorToMap(
                StartupLedgerData.debtorFromMap(
                  Map<String, dynamic>.from(e),
                ),
              ),
        ];
      } catch (_) {
        return [];
      }
    }

    List<Map<String, dynamic>> mapTransactions(String raw) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return [
          for (final e in list)
            if (e is Map)
              StartupLedgerData.transactionToMap(
                StartupLedgerData.transactionFromMap(
                  Map<String, dynamic>.from(e),
                ),
              ),
        ];
      } catch (_) {
        return [];
      }
    }

    List<Map<String, dynamic>> mapCashbook(String raw) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return [
          for (final e in list)
            if (e is Map) CashbookEntry.fromJson(Map<String, dynamic>.from(e)).toJson(),
        ];
      } catch (_) {
        return [];
      }
    }

    List<Map<String, dynamic>> mapAccounts(String raw) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return [
          for (final e in list)
            if (e is Map)
              StartupLedgerData.financialAccountToMap(
                StartupLedgerData.financialAccountFromMap(
                  Map<String, dynamic>.from(e),
                ),
              ),
        ];
      } catch (_) {
        return [];
      }
    }

    List<Map<String, dynamic>> mapDebtCategories(String raw) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        return [
          for (final e in list)
            if (e is Map)
              StartupLedgerData.debtCategoryToMap(
                StartupLedgerData.debtCategoryFromMap(
                  Map<String, dynamic>.from(e),
                ),
              ),
        ];
      } catch (_) {
        return [];
      }
    }

    try {
      await pushDocList(
        prefsKey: PrefsKeys.debtors,
        subcollection: 'debtors',
        toDocMaps: mapDebtors,
      );
      await pushDocList(
        prefsKey: PrefsKeys.transactions,
        subcollection: 'transactions',
        toDocMaps: mapTransactions,
      );
      await pushDocList(
        prefsKey: PrefsKeys.cashbook,
        subcollection: 'cashbook',
        toDocMaps: mapCashbook,
      );
      await pushDocList(
        prefsKey: PrefsKeys.accounts,
        subcollection: 'accounts',
        toDocMaps: mapAccounts,
      );
      await pushDocList(
        prefsKey: PrefsKeys.debtCategories,
        subcollection: 'debt_categories',
        toDocMaps: mapDebtCategories,
      );

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await ud.set({
        'ledgerSchemaV': 2,
        'ledgerUpdatedMs': nowMs,
        'storeDisplayHint': prefs.getString(PrefsKeys.userName),
        'registeredPhoneHint': prefs.getString(PrefsKeys.phoneDocId),
      }, SetOptions(merge: true));
      await prefs.setInt(PrefsKeys.lastLedgerSyncedMs, nowMs);
      try {
        _ref.read(ledgerSyncUiProvider.notifier).markPushSucceeded();
      } catch (_) {}
      return true;
    } on FirebaseException catch (e, st) {
      debugPrint('LedgerFirestoreSync pushNow: $e\n$st');
      final ar = e.code == 'permission-denied'
          ? 'لا صلاحية للكتابة في السحابة. للكاشير: تأكّد أنّ قواعد Firebase نُشرت وتتضمّن المزامنة للفريق.'
          : 'تعذّر المزامنة: ${e.message ?? e.code}';
      try {
        _ref.read(ledgerSyncUiProvider.notifier).markPushFailed(ar);
      } catch (_) {}
      return false;
    } catch (e, st) {
      debugPrint('LedgerFirestoreSync pushNow: $e\n$st');
      try {
        _ref.read(ledgerSyncUiProvider.notifier).markPushFailed('$e');
      } catch (_) {}
      return false;
    }
  }
}

final ledgerFirestoreSyncProvider = Provider<LedgerFirestoreSync>((ref) {
  final sync = LedgerFirestoreSync(ref);
  sync.bindPersistHook();

  ref.onDispose(() {
    sync.unbindPersistHook();
    unawaited(sync.detach());
  });
  return sync;
});
