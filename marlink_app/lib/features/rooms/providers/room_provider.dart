import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../data/room_repository.dart';
import '../domain/models/room_model.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository();
});

class RoomsState {
  final bool isLoading;
  final List<RoomModel> rooms;
  final RoomModel? currentRoom;
  final String? errorMessage;

  const RoomsState({
    this.isLoading = false,
    this.rooms = const [],
    this.currentRoom,
    this.errorMessage,
  });

  RoomsState copyWith({
    bool? isLoading,
    List<RoomModel>? rooms,
    RoomModel? currentRoom,
    String? errorMessage,
  }) {
    return RoomsState(
      isLoading: isLoading ?? this.isLoading,
      rooms: rooms ?? this.rooms,
      currentRoom: currentRoom ?? this.currentRoom,
      errorMessage: errorMessage,
    );
  }
}

final roomsNotifierProvider = StateNotifierProvider<RoomsNotifier, RoomsState>((ref) {
  final repository = ref.watch(roomRepositoryProvider);
  return RoomsNotifier(repository);
});

class RoomsNotifier extends StateNotifier<RoomsState> {
  final RoomRepository _repository;

  RoomsNotifier(this._repository) : super(const RoomsState()) {
    loadRooms();
  }

  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final rooms = await _repository.getRooms();
      RoomModel? current = state.currentRoom;

      if (rooms.isNotEmpty) {
        if (current == null || !rooms.any((r) => r.id == current!.id)) {
          current = rooms.first;
        } else {
          current = rooms.firstWhere((r) => r.id == current!.id);
        }
      } else {
        current = null;
      }

      state = state.copyWith(
        isLoading: false,
        rooms: rooms,
        currentRoom: current,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.friendlyErrorMessage);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load rooms.');
    }
  }

  void selectRoom(RoomModel room) {
    state = state.copyWith(currentRoom: room);
  }

  Future<bool> createRoom(String name, String? description) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newRoom = await _repository.createRoom(name: name, description: description);
      await loadRooms();
      state = state.copyWith(
        isLoading: false,
        currentRoom: newRoom,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.friendlyErrorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to create room: $e');
      return false;
    }
  }

  Future<bool> joinRoom(String code, String? nickname) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final joinedRoom = await _repository.joinRoom(code: code, customNickname: nickname);
      await loadRooms();
      state = state.copyWith(
        isLoading: false,
        currentRoom: joinedRoom,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.friendlyErrorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to join room: $e');
      return false;
    }
  }

  Future<void> leaveRoom(int roomId) async {
    try {
      await _repository.leaveRoom(roomId);
      final updated = state.rooms.where((r) => r.id != roomId).toList();
      state = state.copyWith(
        rooms: updated,
        currentRoom: updated.isNotEmpty ? updated.first : null,
      );
    } catch (_) {}
  }

  Future<void> removeMember(int roomId, int userId) async {
    try {
      await _repository.removeMember(roomId, userId);
      // Reload room details
      final updatedRoom = await _repository.getRoomDetails(roomId);
      final updatedRooms = state.rooms.map((r) => r.id == roomId ? updatedRoom : r).toList();
      state = state.copyWith(
        rooms: updatedRooms,
        currentRoom: state.currentRoom?.id == roomId ? updatedRoom : state.currentRoom,
      );
    } catch (_) {}
  }
}
