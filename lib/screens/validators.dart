final _emailRe = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

String? notEmpty(String? v, String field) => (v == null || v.trim().isEmpty) ? '$field không được để trống' : null;

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email không được để trống';
  return _emailRe.hasMatch(v.trim()) ? null : 'Email không đúng định dạng';
}

String? validatePassword(String? v) => (v == null || v.length < 6) ? 'Mật khẩu tối thiểu 6 ký tự' : null;

String? validatePrice(String? v) {
  final p = double.tryParse(v?.trim() ?? '');
  return (p == null || p < 0) ? 'Giá phải là số không âm' : null;
}
