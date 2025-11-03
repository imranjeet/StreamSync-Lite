import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:streamsync_lite/features/home/home_bloc.dart';
import 'package:streamsync_lite/features/home/home_event.dart';
import 'package:streamsync_lite/features/home/home_state.dart';
import 'package:streamsync_lite/features/home/home_repository.dart';

class MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  group('HomeBloc', () {
    late HomeBloc homeBloc;

    setUp(() {
      // Note: In real implementation, would need to inject repository
      homeBloc = HomeBloc();
    });

    test('initial state is HomeInitial', () {
      expect(homeBloc.state, isA<HomeInitial>());
    });

    blocTest<HomeBloc, HomeState>(
      'emits [Loading, Loaded] when videos are loaded successfully',
      build: () => homeBloc,
      act: (bloc) => bloc.add(HomeLoadVideos()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'emits [Loading, Error] when videos fail to load',
      build: () => homeBloc,
      act: (bloc) => bloc.add(HomeLoadVideos()),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeError>(),
      ],
      errors: () => [isA<Exception>()],
    );
  });
}

