class ChatNotification {
  final String title;
  final String body;
  final String userAvatarUrl; 

  ChatNotification({required this.title, required this.body, required this.userAvatarUrl});
}

class GroupNotification {
  final String title;
  final String body;
  final String groupAvatarUrl; 

  GroupNotification({required this.title, required this.body, required this.groupAvatarUrl});
}
