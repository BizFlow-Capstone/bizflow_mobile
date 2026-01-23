# 📝 REPORT TEMPLATE

**Use this template để tạo report cho mỗi module/phase/feature**

---

## [📋 REPORT TITLE] - [MODULE/PHASE/FEATURE NAME]

**Date Completed:** [Date]  
**Duration:** [Time spent] hours  
**Status:** ✅ Complete / ⏳ In Progress / ❌ Blocked  
**Reported By:** [Your name]  

---

## 📌 QUICK SUMMARY

### What Was Done
Một câu mô tả ngắn gọn về công việc hoàn thành.

### Key Achievements
- ✅ Achievement 1
- ✅ Achievement 2
- ✅ Achievement 3

### Status
✅ On Track / ⏳ Delayed / ❌ Blocked
**Next Phase:** [What comes next]

---

## 📊 STATISTICS

### Code
```
Files Created:        [N] files
Files Modified:       [N] files
Lines of Code:        [N] LOC
Classes Created:      [N]
Methods Added:        [N]
Comments Added:       [N]%
```

### Quality
```
Type Safety:          [%]%
Code Duplication:     [%]%
Lint Issues:          [N]
Test Coverage:        [%]%
```

### Performance
```
Build Time:           [N]s
APK Size:             [N]MB
Memory Usage:         [N]MB
Frame Rate:           [N]fps
```

### Effort
```
Time Spent:           [N] hours
Team Size:            [N] person/people
Productivity:         [N] LOC/hour
```

---

## 🎯 DELIVERABLES

### Completed Items
- [x] Item 1
- [x] Item 2
- [x] Item 3
- [ ] Item 4 (Not yet)

### Scope Coverage
```
Planned:   [N] items
Completed: [N] items
Progress:  [%]%
```

---

## 📝 DETAILED DESCRIPTION

### Overview
Mô tả chi tiết về công việc được làm.

### Architecture/Design
Giải thích kiến trúc hoặc thiết kế được sử dụng.

```
┌─────────┐
│ System  │
└─────────┘
    ↓
(Diagram if applicable)
```

### Implementation Details
1. **Component 1**
   - What: [Description]
   - How: [Implementation approach]
   - Why: [Rationale]

2. **Component 2**
   - What: [Description]
   - How: [Implementation approach]
   - Why: [Rationale]

### Code Samples
```dart
// Example of key implementation
class Example {
  void doSomething() {
    // Your code here
  }
}
```

---

## 🧪 TESTING

### Test Coverage
```
Unit Tests:          [N] tests, [%]% coverage
Widget Tests:        [N] tests, [%]% coverage
Integration Tests:   [N] tests, [%]% coverage
Total:               [N] tests
```

### Test Results
```
✅ Passed:   [N]
❌ Failed:   [N]
⏭️ Skipped:  [N]
Success Rate: [%]%
```

### Known Issues / Edge Cases
- Issue 1: [Description] - [Status: Fixed/Open/Accepted]
- Issue 2: [Description] - [Status: Fixed/Open/Accepted]

### Browser/Device Testing
- ✅ Android
- ✅ iOS
- ✅ Web (if applicable)

---

## 🚨 ISSUES & CHALLENGES

### Problems Encountered
1. **Issue 1: [Title]**
   - Description: [What was the problem]
   - Root Cause: [Why it happened]
   - Solution: [How it was fixed]
   - Time Impact: [Time spent fixing]
   - Prevention: [How to prevent next time]

2. **Issue 2: [Title]**
   - Description: [...]
   - Root Cause: [...]
   - Solution: [...]
   - Time Impact: [...]
   - Prevention: [...]

### Performance Concerns
- Concern 1: [Details] - Solution: [How to improve]
- Concern 2: [Details] - Solution: [How to improve]

### Security Considerations
- Risk 1: [Details] - Mitigation: [How addressed]
- Risk 2: [Details] - Mitigation: [How addressed]

### Technical Debt
- [ ] Item 1: [Description] - Severity: High/Medium/Low
- [ ] Item 2: [Description] - Severity: High/Medium/Low

---

## 📂 FILES CHANGED

### New Files Created
```
✨ lib/core/module/file1.dart         (50 lines)
✨ lib/core/module/file2.dart         (120 lines)
✨ lib/shared/utils/file3.dart        (80 lines)

Total new files: [N]
Total lines added: [N]
```

### Files Modified
```
🔄 lib/main.dart                      (+10 -5 lines)
🔄 pubspec.yaml                       (+2 dependencies)

Total modified: [N]
```

### Files Deleted
```
❌ lib/old_module/unused_file.dart

Total deleted: [N]
```

### Detailed Changes
| File | Type | Change | Reason |
|------|------|--------|--------|
| file1.dart | Created | New module | Required for feature |
| file2.dart | Modified | Added methods | Extended functionality |
| file3.dart | Deleted | Removed | No longer needed |

---

## ✅ TESTING VERIFICATION

### Manual Testing Checklist
- [ ] Feature works on Android
- [ ] Feature works on iOS
- [ ] No crashes observed
- [ ] Performance acceptable
- [ ] UI looks correct
- [ ] Error handling works
- [ ] Offline mode works (if applicable)
- [ ] All edge cases tested

### Code Review Checklist
- [ ] Code follows style guide
- [ ] No hardcoded values
- [ ] Proper error handling
- [ ] Type safety maintained
- [ ] Documentation complete
- [ ] No duplicate code
- [ ] Performance optimized
- [ ] Security reviewed

---

## 📈 METRICS & MONITORING

### Before/After Comparison
```
Metric              Before    After     Change
─────────────────────────────────────────────
Build Time          [N]s      [N]s      [+/-]%
APK Size            [N]MB     [N]MB     [+/-]%
Test Coverage       [N]%      [N]%      [+/-]%
Lines of Code       [N]       [N]       [+/-]%
```

### Performance Impact
- CPU Usage: [Normal/High/Low]
- Memory Usage: [Normal/High/Low]
- Battery Impact: [Normal/High/Low]
- Network Impact: [Normal/High/Low]

### Code Quality Metrics
- Cyclomatic Complexity: [Low/Medium/High]
- Code Duplication: [Low/Medium/High]
- Maintainability Index: [High/Medium/Low]

---

## 📚 DOCUMENTATION

### Documentation Added
- ✅ Code comments: [Yes/No/Partial]
- ✅ README updated: [Yes/No]
- ✅ API documentation: [Yes/No/N/A]
- ✅ Architecture docs: [Yes/No/Partial]
- ✅ Example code: [Yes/No/Partial]

### References & Resources
- Resource 1: [Link]
- Resource 2: [Link]
- Design Doc: [Link]
- API Docs: [Link]

---

## 🔄 DEPENDENCIES & COMPATIBILITY

### New Dependencies Added
```
Dependency 1@version    - Reason: [Why needed]
Dependency 2@version    - Reason: [Why needed]
```

### Compatibility
- ✅ Flutter [Version]
- ✅ Dart [Version]
- ✅ Android SDK [Version]
- ✅ iOS SDK [Version]
- ✅ Previous versions

### Breaking Changes
- Breaking Change 1: [What changed, how to migrate]
- Breaking Change 2: [What changed, how to migrate]

---

## 🎓 LESSONS LEARNED

### What Went Well
1. [Positive point 1]
2. [Positive point 2]
3. [Positive point 3]

### What Could Be Improved
1. [Area for improvement 1]
2. [Area for improvement 2]
3. [Area for improvement 3]

### Recommendations for Next Time
1. [Recommendation 1]
2. [Recommendation 2]
3. [Recommendation 3]

---

## 🚀 NEXT STEPS

### Immediate Next (This Week)
- [ ] Task 1: [Description]
- [ ] Task 2: [Description]
- [ ] Task 3: [Description]

### Short Term (Next 2 Weeks)
- [ ] Task 1: [Description]
- [ ] Task 2: [Description]

### Long Term (Next Month)
- [ ] Task 1: [Description]
- [ ] Task 2: [Description]

### Blocked By
- [ ] Item 1: [Description] - Expected completion: [Date]
- [ ] Item 2: [Description] - Expected completion: [Date]

### Dependencies
- Depends on: [What this depends on]
- Needed for: [What depends on this]

---

## 📝 NOTES & COMMENTS

### Additional Information
[Any additional information that doesn't fit in other sections]

### Team Feedback
- Feedback 1: [From whom: message]
- Feedback 2: [From whom: message]

### Follow-up Items
- [ ] Follow-up 1
- [ ] Follow-up 2
- [ ] Follow-up 3

---

## 👥 CONTRIBUTORS

- [Name 1]: [Role/Contribution]
- [Name 2]: [Role/Contribution]
- [Name 3]: [Role/Contribution]

---

## 📋 SIGN-OFF

### Verification
- Code Review: ✅ Approved by [Reviewer]
- Quality Check: ✅ Passed
- Testing: ✅ Complete
- Documentation: ✅ Complete

### Approval
- **Report Created By:** [Your Name]
- **Date:** [Date]
- **Status:** ✅ Ready for next phase / ⏳ Awaiting approval / ❌ Needs revision

---

## 📎 ATTACHMENTS

### Screenshots/Diagrams
[If applicable, add screenshots showing the feature/module]

### Code Snippets
[Key code examples if relevant]

### Links
- GitHub PR: [Link]
- Figma Design: [Link]
- Issue Tracker: [Link]
- CI/CD Pipeline: [Link]

---

## 📌 SUMMARY FOR LAZY READERS

**TL;DR:**
In 1-2 sentences, what was accomplished?

**Key Numbers:**
- [Stat 1]
- [Stat 2]
- [Stat 3]

**Status:** ✅ Done

---

**Version:** 1.0  
**Last Updated:** [Date]

---

**Hết - Report Template**
