// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:messenger/api/backend/schema.dart';
import 'package:messenger/config.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/session.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/auth.dart';
import 'package:messenger/domain/repository/call.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/settings.dart';
import 'package:messenger/domain/service/auth.dart';
import 'package:messenger/domain/service/call.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/domain/service/user.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/provider/hive/application_settings.dart';
import 'package:messenger/provider/hive/background.dart';
import 'package:messenger/provider/hive/blocklist.dart';
import 'package:messenger/provider/hive/call_rect.dart';
import 'package:messenger/provider/hive/chat.dart';
import 'package:messenger/provider/hive/chat_call_credentials.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/provider/hive/contact.dart';
import 'package:messenger/provider/hive/draft.dart';
import 'package:messenger/provider/hive/media_settings.dart';
import 'package:messenger/provider/hive/monolog.dart';
import 'package:messenger/provider/hive/my_user.dart';
import 'package:messenger/provider/hive/session.dart';
import 'package:messenger/provider/hive/user.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/store/auth.dart';
import 'package:messenger/store/call.dart';
import 'package:messenger/store/chat.dart';
import 'package:messenger/store/my_user.dart';
import 'package:messenger/store/settings.dart';
import 'package:messenger/store/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../mock/overflow_error.dart';
import '../mock/platform_utils.dart';
import 'chat_update_attachments_test.mocks.dart';

@GenerateMocks([GraphQlProvider, PlatformRouteInformationProvider])
void main() async {
  PlatformUtils = PlatformUtilsMock();

  final dio = Dio(BaseOptions());
  final dioAdapter = DioAdapter(dio: dio);
  PlatformUtils.client = dio;

  dioAdapter.onGet(
    'oldRef.png',
    (server) {
      server.reply(
        200,
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
        ),
      );
    },
  );

  dioAdapter.onGet(
    'updatedRef.png',
    (server) {
      server.reply(
        200,
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
        ),
      );
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();
  Hive.init('./test/.temp_hive/chat_update_image');
  Config.files = '';

  var chatData = {
    'id': '0d72d245-8425-467a-9ebd-082d4f47850b',
    'name': 'startname',
    'avatar': null,
    'members': {'nodes': []},
    'kind': 'GROUP',
    'isHidden': false,
    'muted': null,
    'directLink': null,
    'createdAt': '2021-12-15T15:11:18.316846+00:00',
    'updatedAt': '2021-12-15T15:11:18.316846+00:00',
    'lastReads': [
      {'memberId': 'me', 'at': '2022-01-01T07:27:30.151628+00:00'},
    ],
    'lastDelivery': '1970-01-01T00:00:00+00:00',
    'lastItem': null,
    'lastReadItem': null,
    'unreadCount': 0,
    'totalCount': 0,
    'ongoingCall': null,
    'ver': '0'
  };

  var recentChats = {
    'recentChats': {
      'nodes': [chatData]
    }
  };

  var blacklist = {
    'edges': [],
    'pageInfo': {
      'endCursor': 'endCursor',
      'hasNextPage': false,
      'startCursor': 'startCursor',
      'hasPreviousPage': false,
    }
  };

  var graphQlProvider = MockGraphQlProvider();
  Get.put<GraphQlProvider>(graphQlProvider);
  when(graphQlProvider.disconnect()).thenAnswer((_) => () {});
  when(graphQlProvider.keepOnline()).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.recentChatsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());

  when(graphQlProvider.chatEvents(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
    any,
  )).thenAnswer((_) => const Stream.empty());

  when(graphQlProvider
          .getChat(const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')))
      .thenAnswer(
    (_) => Future.value(GetChat$Query.fromJson({'chat': chatData})),
  );

  when(graphQlProvider.readChat(
          const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          const ChatItemId('6d1c8e23-8583-4e3d-9ebb-413c95c786b0')))
      .thenAnswer((_) => Future.value(null));

  when(graphQlProvider.chatItems(
          const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
          last: 50))
      .thenAnswer(
    (_) => Future.value(GetMessages$Query.fromJson({
      'chat': {
        'items': {
          'edges': [
            {
              'node': {
                '__typename': 'ChatMessage',
                'id': '6d1c8e23-8583-4e3d-9ebb-413c95c786b0',
                'chatId': '0d72d245-8425-467a-9ebd-082d4f47850b',
                'author': {
                  'id': 'me',
                  'num': '1234567890123456',
                  'mutualContactsCount': 0,
                  'isDeleted': false,
                  'isBlocked': {'blacklisted': false, 'ver': '0'},
                  'presence': 'AWAY',
                  'ver': '0',
                },
                'at': '2022-02-01T09:32:52.246988+00:00',
                'ver': '10',
                'repliesTo': [],
                'text': null,
                'editedAt': null,
                'attachments': [
                  {
                    '__typename': 'ImageAttachment',
                    'id': 'c7f4b137-28b2-40aa-824f-891387e3c0b5',
                    'filename': 'filename.png',
                    'original': {'relativeRef': 'oldRef.png'},
                    'big': {'relativeRef': 'oldRef.png'},
                    'medium': {'relativeRef': 'oldRef.png'},
                    'small': {'relativeRef': 'oldRef.png'},
                  }
                ]
              },
              'cursor': '123'
            }
          ],
          'pageInfo': {
            'endCursor': 'endCursor',
            'hasNextPage': false,
            'startCursor': 'startCursor',
            'hasPreviousPage': false,
          }
        }
      }
    })),
  );

  when(graphQlProvider.attachments(any)).thenAnswer(
    (_) => Future.value(GetAttachments$Query.fromJson({
      'chatItem': {
        'node': {
          '__typename': 'ChatMessage',
          'repliesTo': [],
          'attachments': [
            {
              '__typename': 'ImageAttachment',
              'id': 'c7f4b137-28b2-40aa-824f-891387e3c0b5',
              'original': {'relativeRef': 'updatedRef.png'},
              'filename': 'filename.png',
              'big': {'relativeRef': 'updatedRef.png'},
              'medium': {'relativeRef': 'updatedRef.png'},
              'small': {'relativeRef': 'updatedRef.png'}
            }
          ]
        }
      }
    })),
  );

  when(graphQlProvider.recentChats(
    first: 120,
    after: null,
    last: null,
    before: null,
  )).thenAnswer((_) => Future.value(RecentChats$Query.fromJson(recentChats)));

  when(graphQlProvider.incomingCalls()).thenAnswer((_) => Future.value(
      IncomingCalls$Query$IncomingChatCalls.fromJson({'nodes': []})));
  when(graphQlProvider.incomingCallsTopEvents(3))
      .thenAnswer((_) => const Stream.empty());
  when(graphQlProvider.favoriteChatsEvents(any))
      .thenAnswer((_) => const Stream.empty());
  when(graphQlProvider.myUserEvents(any))
      .thenAnswer((realInvocation) => const Stream.empty());
  when(graphQlProvider.getUser(any))
      .thenAnswer((_) => Future.value(GetUser$Query.fromJson({'user': null})));
  when(graphQlProvider.getMonolog()).thenAnswer(
    (_) => Future.value(GetMonolog$Query.fromJson({'monolog': null}).monolog),
  );

  when(graphQlProvider.getBlocklist(
    first: 120,
    after: null,
    last: null,
    before: null,
  )).thenAnswer(
    (_) => Future.value(GetBlocklist$Query$Blocklist.fromJson(blacklist)),
  );

  var sessionProvider = Get.put(SessionDataHiveProvider());
  await sessionProvider.init();
  await sessionProvider.clear();
  sessionProvider.setCredentials(
    Credentials(
      Session(
        const AccessToken('token'),
        PreciseDateTime.now().add(const Duration(days: 1)),
      ),
      RememberedSession(
        const RefreshToken('token'),
        PreciseDateTime.now().add(const Duration(days: 1)),
      ),
      const UserId('me'),
    ),
  );

  var contactProvider = Get.put(ContactHiveProvider());
  await contactProvider.init();
  await contactProvider.clear();
  var draftProvider = Get.put(DraftHiveProvider());
  await draftProvider.init();
  await draftProvider.clear();
  var userProvider = Get.put(UserHiveProvider());
  await userProvider.init();
  await userProvider.clear();
  var chatProvider = Get.put(ChatHiveProvider());
  await chatProvider.init();
  await chatProvider.clear();
  var settingsProvider = MediaSettingsHiveProvider();
  await settingsProvider.init();
  await settingsProvider.clear();
  var applicationSettingsProvider = ApplicationSettingsHiveProvider();
  await applicationSettingsProvider.init();
  var backgroundProvider = BackgroundHiveProvider();
  await backgroundProvider.init();
  var callRectProvider = CallRectHiveProvider();
  await callRectProvider.init();
  var myUserProvider = MyUserHiveProvider();
  await myUserProvider.init();
  await myUserProvider.clear();
  var blacklistedUsersProvider = BlocklistHiveProvider();
  await blacklistedUsersProvider.init();
  var monologProvider = MonologHiveProvider();
  await monologProvider.init();

  var messagesProvider = Get.put(ChatItemHiveProvider(
    const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b'),
  ));
  await messagesProvider.init(userId: const UserId('me'));
  await messagesProvider.clear();
  var credentialsProvider = ChatCallCredentialsHiveProvider();
  await credentialsProvider.init();

  Widget createWidgetForTesting({required Widget child}) {
    FlutterError.onError = ignoreOverflowErrors;
    return MaterialApp(
      theme: Themes.light(),
      home: Builder(
        builder: (BuildContext context) {
          router.context = context;
          return Scaffold(body: child);
        },
      ),
    );
  }

  testWidgets('ChatView successfully refreshes image attachments',
      (WidgetTester tester) async {
    AuthService authService = Get.put(
      AuthService(
        Get.put<AbstractAuthRepository>(AuthRepository(Get.find())),
        sessionProvider,
      ),
    );
    await authService.init();

    router = RouterState(authService);
    router.provider = MockPlatformRouteInformationProvider();

    UserRepository userRepository =
        Get.put(UserRepository(graphQlProvider, userProvider));
    AbstractSettingsRepository settingsRepository = Get.put(
      SettingsRepository(
        settingsProvider,
        applicationSettingsProvider,
        backgroundProvider,
        callRectProvider,
      ),
    );

    AbstractCallRepository callRepository = CallRepository(
      graphQlProvider,
      userRepository,
      credentialsProvider,
      settingsRepository,
      me: const UserId('me'),
    );

    AbstractChatRepository chatRepository = Get.put<AbstractChatRepository>(
      ChatRepository(
        graphQlProvider,
        chatProvider,
        callRepository,
        draftProvider,
        userRepository,
        sessionProvider,
        monologProvider,
        me: const UserId('me'),
      ),
    );

    Get.put(
      MyUserService(
        authService,
        Get.put(
          MyUserRepository(
            graphQlProvider,
            myUserProvider,
            blacklistedUsersProvider,
            userRepository,
          ),
        ),
      ),
    );

    Get.put(UserService(userRepository));
    ChatService chatService = Get.put(ChatService(chatRepository, authService));
    Get.put(CallService(authService, chatService, callRepository));

    await tester.pumpWidget(createWidgetForTesting(
      child: const ChatView(ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')),
    ));

    await tester.runAsync(() => Future.delayed(1.seconds));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      find.byKey(const Key('Image_oldRef.png'), skipOffstage: false),
      findsOneWidget,
    );

    final RxChat chat = chatRepository
        .chats[const ChatId('0d72d245-8425-467a-9ebd-082d4f47850b')]!;

    await tester
        .runAsync(() => chat.updateAttachments(chat.messages.first.value));
    await tester.runAsync(() => Future.delayed(1.seconds));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(
      find.byKey(const Key('Image_updatedRef.png'), skipOffstage: false),
      findsOneWidget,
    );

    await tester.runAsync(() => Future.delayed(1.seconds));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    await Get.deleteAll(force: true);
  });
}