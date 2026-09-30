# MEME AI AGENT MASTER RULE

> This file defines the mandatory coding behavior for AI agents working on the Meme application.
> Follow these rules before, during, and after every coding task.

---

# 1. CORE PRINCIPLE

Meme is an existing Flutter application.

The existing codebase is the source of truth.

DO NOT treat Meme as a new project.

Always prefer:

```text
Existing code
→ Existing architecture
→ Existing UI/UX patterns
→ Existing data models
→ Existing services
→ User request
→ Conservative inference
→ AI suggestions
```

The AI must adapt to Meme.

Meme must NOT be redesigned to fit the AI's preferences.

---

# 2. GOLDEN RULE

## CHANGE ONLY WHAT IS NECESSARY.

Before changing any code, ask:

> "Is this change required to fulfill the user's current request?"

If NO:

**DO NOT CHANGE IT.**

Do not use a local task as an excuse to:

* refactor unrelated code
* redesign unrelated UI
* rename unrelated variables
* reorganize folders
* change architecture
* change Firebase structure
* change theme
* update unrelated dependencies
* rewrite existing services

---

# 3. SOURCE OF TRUTH

When deciding how something should work, use this priority:

```text
1. Existing implementation
2. Existing reusable components
3. Existing architecture
4. Existing data models
5. Existing project documentation
6. User's explicit request
7. Conservative inference
8. AI suggestion
```

Never invent project behavior when existing code can answer the question.

---

# 4. REQUIRED WORKFLOW

Every coding task MUST follow:

```text
UNDERSTAND
↓
SEARCH
↓
SCOPE
↓
IMPLEMENT
↓
VERIFY
↓
REPORT
```

---

# 5. BEFORE CODING

Before writing code:

### Step 1 — Understand the request

Identify:

* What the user wants
* What screen/feature is affected
* What behavior should change
* What behavior must remain unchanged

### Step 2 — Inspect existing code

Search for:

* related screens
* widgets
* models
* services
* repositories
* providers/controllers
* Firebase operations
* utilities
* similar implementations

### Step 3 — Find reusable code

Before creating anything new, ask:

> "Does Meme already have something that does this?"

Reuse existing code whenever possible.

### Step 4 — Define scope

Internally identify:

```text
REQUIRED FILES
RELATED FILES
UNRELATED FILES
```

Only modify the first two categories when necessary.

---

# 6. NEVER GUESS WITHOUT CHECKING

Do NOT invent:

* Firebase collections
* Firebase fields
* API endpoints
* model properties
* navigation routes
* services
* providers
* UI components
* business rules
* category names

if equivalent information already exists in the codebase.

Search first.

---

# 7. CONSERVATIVE INFERENCE

Inference is allowed, but must be conservative.

Use this order:

```text
Explicit user requirement
↓
Existing code pattern
↓
Existing project behavior
↓
Small reasonable assumption
```

If a decision could significantly affect:

* architecture
* database
* security
* financial data
* navigation
* existing user behavior

ASK the user before making the decision.

If the decision is small and reversible, follow the closest existing pattern.

---

# 8. DO NOT OVER-ENGINEER

Prefer:

```text
Simple + consistent + maintainable
```

over:

```text
Complex + clever + unnecessary
```

Do not introduce a new architecture merely because it is technically more modern.

Do not add abstraction layers unless they solve a real problem.

---

# 9. NO UNREQUESTED REFACTORING

If the user asks:

> "Fix feature A"

Do NOT also:

* clean feature B
* rename feature C
* refactor service D
* rewrite model E
* reorganize the project

Even if the code could be improved.

If you discover an unrelated improvement:

```text
DO NOT IMPLEMENT IT.
```

Mention it separately if useful.

---

# 10. PRESERVE USER WORK

The user's existing modifications are sacred.

Never:

* overwrite unrelated changes
* revert user changes
* reset Git
* discard uncommitted work
* force-push
* delete branches

unless explicitly requested.

If a file already contains unrelated changes, preserve them.

---

# 11. MINIMAL FILE CHANGES

Modify the smallest possible number of files.

Every changed file must have a reason.

If 10 files are changed for a simple feature, reconsider whether all 10 are actually necessary.

Do not perform project-wide replacements for local tasks.

---

# 12. MEME UI CONSISTENCY

All UI changes MUST match the existing Meme design system.

Maintain consistency in:

* colors
* typography
* spacing
* border radius
* shadows
* buttons
* cards
* icons
* dialogs
* bottom sheets
* navigation
* animations
* loading states
* empty states
* error states

Before creating a new UI component:

```text
Search existing components
↓
Reuse if possible
↓
Extend if appropriate
↓
Create new only when necessary
```

---

# 13. NEVER RANDOMLY CHANGE THE THEME

Do NOT modify the global theme to solve a local problem.

Avoid changing:

* ThemeData
* global colors
* global typography
* global component themes

unless the user explicitly requests a global theme change.

A local UI problem should normally receive a local solution.

---

# 14. REUSE DESIGN TOKENS

If Meme already has:

* AppColors
* theme colors
* text styles
* spacing constants
* radius constants
* icon registry
* shared widgets

USE THEM.

Do not hardcode random values when an existing design token exists.

---

# 15. COMPONENT REUSE

Before creating:

* Button
* Card
* Dialog
* BottomSheet
* TextField
* Avatar
* TransactionCard
* CategorySelector
* ImageViewer
* LoadingIndicator
* EmptyState

search for an existing implementation.

Avoid duplicate components such as:

```text
CustomButton
CustomButton2
NewCustomButton
MemeButton
MemeButtonNew
```

when one reusable component already exists.

---

# 16. STATE MANAGEMENT

Follow the state-management pattern already used by the relevant feature.

Do NOT introduce a different architecture because you prefer it.

If the surrounding feature uses:

```text
Provider → use Provider
Riverpod → use Riverpod
Bloc → use Bloc
ChangeNotifier → follow the existing pattern
```

Consistency is more important than personal preference.

---

# 17. NAMING

Follow existing naming conventions.

Before creating a new name, search for similar concepts.

Do not create multiple names for the same concept.

Example:

If the project consistently uses:

```text
SpendingMoment
```

do not introduce:

```text
MoneyMoment
ExpenseMoment
TransactionMoment
```

for the same underlying concept without a reason.

---

# 18. FIREBASE RULES

Firebase structure must be treated as existing infrastructure.

Before modifying Firebase:

1. Inspect existing collections.
2. Inspect document structures.
3. Inspect models.
4. Inspect read/write operations.
5. Inspect related services/functions.
6. Check backward compatibility.

Never casually:

* rename fields
* rename collections
* move documents
* change data structures
* delete fields

---

# 19. BACKWARD COMPATIBILITY

When adding new fields or behavior:

Assume old data may still exist.

Handle missing fields safely when appropriate.

Do not assume every old document contains newly introduced fields.

New functionality should not unnecessarily break existing users/data.

---

# 20. FINANCIAL DATA SAFETY

Meme handles financial information.

Never silently modify:

* amount
* transaction date
* category
* balance
* budget
* group budget
* transaction ownership

unless required by the requested feature.

AI-generated financial values should be treated carefully and confirmed when appropriate.

---

# 21. CATEGORY RULE

When AI selects a transaction category:

ONLY use categories already available in Meme.

For example:

```text
Ăn uống
Mua sắm
Di chuyển
Giải trí
Giáo dục
Lương
Quà tặng
```

Do NOT invent new categories unless the user explicitly requests category creation.

If confidence is low:

```text
suggest → allow user correction
```

rather than silently forcing an uncertain category.

---

# 22. AI FEATURES

Meme may contain AI functionality such as:

* image classification
* category recognition
* receipt OCR
* amount extraction
* caption generation
* voice expense extraction
* recommendations

AI functionality must integrate with the existing architecture.

Do NOT create isolated duplicate AI pipelines if an existing service already handles the relevant task.

AI should assist the user.

It should not silently overwrite important user data.

---

# 23. VOICE INPUT

Voice recognition can be imperfect.

Handle:

* silence
* partial speech
* background noise
* missing amount
* missing category
* ambiguous speech
* recognition errors

If AI extracts:

```text
amount
caption
category
```

do not assume all three are correct.

Follow the existing confirmation/edit flow where applicable.

---

# 24. ANIMATION

Meme is playful and modern.

Animations should be:

* intentional
* smooth
* short
* consistent
* useful

Do NOT add animation merely because it looks impressive.

Search for existing animation patterns before introducing a new one.

Avoid unnecessary animation packages.

---

# 25. PERFORMANCE

Do not introduce unnecessary:

* rebuilds
* network requests
* Firebase reads
* image processing
* expensive animations
* large dependencies
* background tasks

For image/video/AI features, consider:

```text
memory
network usage
latency
battery
device limitations
```

especially on lower-end Android devices.

---

# 26. DEPENDENCIES

Before adding a package:

1. Check whether Flutter/Dart already supports the feature.
2. Check existing dependencies.
3. Check existing internal utilities.
4. Add a new package only if genuinely necessary.

Do not add dependencies just for convenience.

---

# 27. SECRETS

NEVER hardcode:

* API keys
* passwords
* tokens
* service-account credentials
* private keys

Respect existing:

```text
.env
.env.json
--dart-define
Firebase configuration
```

Never expose secrets in source code.

---

# 28. ERROR HANDLING

Follow the existing error-handling pattern.

Do not silently swallow errors.

Avoid unnecessary:

```dart
catch (_) {}
```

Errors should be:

* handled appropriately
* logged when useful
* communicated to the user when necessary
* prevented from exposing sensitive implementation details

---

# 29. LOGGING

Do not leave temporary debugging code in production.

Remove unnecessary:

```text
print()
debug logs
temporary test values
fake data
temporary comments
```

before completion.

---

# 30. NAVIGATION

Follow existing navigation architecture.

Before adding a route:

1. Search existing routes.
2. Check whether a suitable route already exists.
3. Reuse existing navigation patterns.

Do not redesign navigation for a local feature.

---

# 31. PUBLIC API SAFETY

Avoid changing public:

* constructors
* method signatures
* model interfaces
* service APIs
* providers
* routes

unless required.

If a public API must change:

```text
Search all usages first.
Update all affected callers.
Verify the result.
```

---

# 32. DO NOT BREAK UNRELATED FEATURES

After changing a shared component/service/model, consider its existing consumers.

If the change affects other features:

* identify the affected integration points
* modify only what is required
* preserve existing behavior whenever possible

Do not use a shared component change as an opportunity for a redesign.

---

# 33. WHEN YOU FIND AN EXISTING BUG

If you discover a bug unrelated to the current task:

DO NOT automatically fix it.

Instead report:

```text
I found an unrelated issue in X.
It is outside the current task scope.
I left it unchanged.
```

Fix it only if:

* the user requests it
* it directly prevents the current feature from working

---

# 34. WHEN REQUIREMENTS ARE UNCLEAR

Ask the user when ambiguity affects:

* architecture
* database
* security
* financial data
* destructive operations
* major UX behavior

For minor ambiguity:

follow the closest existing implementation pattern.

If the user says:

> "You decide."

Choose the solution that:

1. Matches existing Meme behavior
2. Requires the fewest changes
3. Preserves compatibility
4. Is easy to maintain
5. Is easy to reverse

---

# 35. TESTING

Before declaring completion:

Check:

```text
✓ Syntax
✓ Imports
✓ Types
✓ Null safety
✓ Affected call sites
✓ UI behavior
✓ Existing behavior
✓ Error cases
```

When possible, run:

```bash
flutter analyze
```

and relevant tests/build checks.

NEVER claim that something was tested if it was not actually tested.

---

# 36. DO NOT HIDE FAILURES

If something cannot be verified:

say so.

Do not claim:

```text
"Everything works."
```

when only static code inspection was performed.

Use accurate statements such as:

```text
"Code changes are complete. I could not run the Android build in this environment."
```

---

# 37. RESPONSE AFTER CODING

After completing a task, report:

## Changed

What was changed.

## Files

Which files were modified and why.

## Preserved

What was intentionally left untouched.

## Verification

What was actually checked/tested.

## Notes

Important assumptions, limitations, or optional improvements.

Keep the report concise.

---

# 38. OPTIONAL IMPROVEMENTS

The AI MAY identify improvements outside the current task.

But:

```text
IDENTIFY ≠ IMPLEMENT
```

Example:

```text
Optional improvement:
The current image cache could potentially be optimized later.

I did not modify it because it is unrelated to the current request.
```

---

# 39. DECISION HIERARCHY

When choosing between solutions:

```text
1. Existing implementation
2. Existing reusable component
3. Existing architecture
4. Smallest safe change
5. Backward compatibility
6. Performance
7. Maintainability
8. New architecture
```

Never choose complexity simply because it appears more sophisticated.

---

# 40. THE MEME STANDARD

Every implementation should feel like it was written by the same developer/team who created the rest of Meme.

The user should NOT feel:

> "This feature looks like it came from another application."

The feature should naturally belong to Meme.

---

# 41. FINAL GOLDEN RULE

Before finishing any task, ask:

> "Did I change anything the user did not ask me to change?"

If YES:

Revert or reconsider that change unless it is technically required.

The default AI behavior must be:

```text
UNDERSTAND
↓
SEARCH
↓
REUSE
↓
MINIMIZE
↓
IMPLEMENT
↓
VERIFY
↓
REPORT
```

NEVER:

```text
GUESS
↓
REWRITE
↓
REFACTOR EVERYTHING
↓
CHANGE UNRELATED CODE
↓
BREAK EXISTING FEATURES
```

---

# END OF MEME AI AGENT MASTER RULE
