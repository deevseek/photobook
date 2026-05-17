class AuthCustomerModel {
  final int id; final String name; final String email; final String? avatar;
  AuthCustomerModel({required this.id, required this.name, required this.email, this.avatar});
  factory AuthCustomerModel.fromJson(Map<String, dynamic> j)=>AuthCustomerModel(id:(j['id'] as num?)?.toInt()??0,name:(j['name']??'-').toString(),email:(j['email']??'-').toString(),avatar:j['avatar']?.toString());
}
