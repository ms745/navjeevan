class NavJeevanValidator {
  // --- Basic Validations ---

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName is required";
    }
    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().length < 2) {
      return "Enter valid full name";
    }
    // Simple alpha check
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return "Name should contain letters only";
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || !RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return "Enter valid 10-digit mobile number";
    }
    return null;
  }

  // --- Financial Validations ---

  static String? validateAnnualIncome(String? value) {
    if (value == null || value.isEmpty) return "Enter annual income";
    final income = double.tryParse(value.replaceAll(',', '').replaceAll('₹', '')) ?? 0;
    if (income < 100000) {
      return "Minimum ₹1 lakh for eligibility";
    }
    return null;
  }

  // --- Multi-Select Validations ---

  static String? validateReasons(List<String> reasons) {
    if (reasons.isEmpty) {
      return "Select at least one reason";
    }
    return null;
  }

  static String? validateRegion(String? region) {
    if (region == null || region == 'Select Region' || region == 'Global') {
      return "Please select your region";
    }
    return null;
  }

  // --- File Validations ---

  static String? validateFilePicked(String? path, String docName) {
    if (path == null || path.isEmpty) {
      return "Upload $docName";
    }
    return null;
  }
}
