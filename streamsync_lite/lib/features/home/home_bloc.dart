import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_repository.dart';
import 'home_state.dart';
import 'home_event.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repository = HomeRepository();

  HomeBloc() : super(HomeInitial()) {
    on<HomeLoadVideos>(_onLoadVideos);
    on<HomeRefreshVideos>(_onRefreshVideos);
  }

  void _onLoadVideos(HomeLoadVideos event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    try {
      final videos = await _repository.getLatestVideos();
      emit(HomeLoaded(videos));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  void _onRefreshVideos(HomeRefreshVideos event, Emitter<HomeState> emit) async {
    try {
      final videos = await _repository.getLatestVideos();
      emit(HomeLoaded(videos));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}

