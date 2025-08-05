import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/models/opp_model.dart';
import 'package:myapp/services/user_storage.dart';

import '../../../services/friend_service.dart';
import '../../../services/realm_friend_service.dart';
import '../../../services/token_service.dart';
import 'friends_list_event.dart';
import 'friends_list_state.dart';

class FriendsListBloc extends Bloc<FriendsListEvent, FriendsListState> {
  List<Map<String, dynamic>> _originalFriendsList = [];
  Map<String, dynamic>? _currentUser;

  FriendsListBloc() : super(FriendsListInitial()) {
    on<LoadCurrentUser>(_onLoadCurrentUser);
    on<LoadFriends>(_onLoadFriends);
    on<RefreshFriends>(_onRefreshFriends);
    on<SearchFriendChanged>(_onSearchFriendChanged);
    on<ClearSearch>(_onClearSearch);
    on<OpenChatWithFriend>(_onOpenChatWithFriend);
    on<LogoutRequested>(_onLogoutRequested);
  }

  void _onLoadCurrentUser(
    LoadCurrentUser event,
    Emitter<FriendsListState> emit,
  ) async {
    final userInfor = await UserStorage.fetchUserInfo();
    _currentUser = userInfor;

    if (state is FriendsListLoaded) {
      emit(
        FriendsListLoaded(
          friends: _originalFriendsList,
          currentUser: _currentUser,
        ),
      );
    }
  }

  void _onLoadFriends(LoadFriends event, Emitter<FriendsListState> emit) async {
    emit(FriendsListLoading());

    try {
      final username = await TokenService.getUsername();

      // Lấy bạn từ Realm (offline)
      final localFriends = RealmFriendService.getAllLocalFriends(username);
      _originalFriendsList = localFriends.map((f) => f.friendToJson()).toList();

      emit(
        FriendsListLoaded(
          friends: _originalFriendsList,
          currentUser: _currentUser,
        ),
      );

      // Gọi API (nếu có mạng)
      final apiFriends = await FriendService.fetchFriends();
      RealmFriendService.saveFriendsToLocal(apiFriends, username);

      // Lấy lại từ Realm sau khi cập nhật
      final updatedFriends = RealmFriendService.getAllLocalFriends(username);
      _originalFriendsList = updatedFriends.map((f) => f.friendToJson()).toList();

      emit(
        FriendsListLoaded(
          friends: _originalFriendsList,
          currentUser: _currentUser,
        ),
      );
    } catch (e) {
      emit(
        FriendsListLoaded(
          friends: _originalFriendsList,
          currentUser: _currentUser,
        ),
      );
    }
  }

  void _onRefreshFriends(
    RefreshFriends event,
    Emitter<FriendsListState> emit,
  ) async {
    add(LoadFriends());
  }

  void _onSearchFriendChanged(
    SearchFriendChanged event,
    Emitter<FriendsListState> emit,
  ) async {
    final filtered = FriendService.filterFriends(
      _originalFriendsList,
      event.query,
    );
    emit(FriendsListSearchResult(filteredFriends: filtered));
  }

  void _onClearSearch(ClearSearch event, Emitter<FriendsListState> emit) async {
    emit(
      FriendsListLoaded(
        friends: _originalFriendsList,
        currentUser: _currentUser,
      ),
    );
  }

  void _onOpenChatWithFriend(
    OpenChatWithFriend event,
    Emitter<FriendsListState> emit,
  ) async {
    emit(ChatOpened(friendData: event.friendData));
  }

  void _onLogoutRequested(
    LogoutRequested event,
    Emitter<FriendsListState> emit,
  ) async {
    await TokenService.clearToken();
    emit(FriendsListLoggedOut());
  }
}
