final RegExp _cjkPattern = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]');

bool containsCjkText(String value) => _cjkPattern.hasMatch(value);
