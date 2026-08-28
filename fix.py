import re

# Fix Bag Screen
with open('lib/features/bag/bag_screen.dart', 'r', encoding='utf-8') as f:
    bag = f.read()

bag = bag.replace('removeFromBag', 'removeItem')
bag = re.sub(r"'\\[^']*'", r"'${items.length}'", bag)

with open('lib/features/bag/bag_screen.dart', 'w', encoding='utf-8') as f:
    f.write(bag)

# Fix Quiz Screen
with open('lib/features/quiz/quiz_screen.dart', 'r', encoding='utf-8') as f:
    quiz = f.read()

quiz = quiz.replace('correctOptionIndex', 'correctIndex')
quiz = quiz.replace('AppColors.accentOrange', 'AppColors.amber')
quiz = re.sub(r"'\\[^']* / \\[^']*'", r"'${_currentIndex + 1} / ${_questions.length}'", quiz)
quiz = quiz.replace(".animate(key: ValueKey('\\-\\')).", ".animate(key: ValueKey('${_currentIndex}-${index}')).")

with open('lib/features/quiz/quiz_screen.dart', 'w', encoding='utf-8') as f:
    f.write(quiz)

# Fix Quiz Result Screen
with open('lib/features/quiz/quiz_result_screen.dart', 'r', encoding='utf-8') as f:
    quiz_res = f.read()

quiz_res = quiz_res.replace('awardQuizMasterBadge', 'earnBadge')
quiz_res = re.sub(r"'\\[^']* / \\[^']*'", r"'${widget.score} / ${widget.total}'", quiz_res)

with open('lib/features/quiz/quiz_result_screen.dart', 'w', encoding='utf-8') as f:
    f.write(quiz_res)

print('Dart files fixed!')
