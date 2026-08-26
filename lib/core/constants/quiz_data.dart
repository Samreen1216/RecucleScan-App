import '../models/quiz_question.dart';

class QuizData {
  static const List<QuizQuestion> questions = [
    QuizQuestion(
      question: 'Which of these plastics is generally easiest to recycle?',
      options: ['PET (#1)', 'PVC (#3)', 'Polystyrene (#6)', 'Polycarbonate (#7)'],
      correctIndex: 0,
      explanation: 'PET (Polyethylene Terephthalate), often used for water bottles, is the most widely recycled plastic.',
    ),
    QuizQuestion(
      question: 'Can you recycle a greasy pizza box?',
      options: ['Yes, the whole thing', 'No, not at all', 'Only the clean top half', 'Yes, if you wash it'],
      correctIndex: 2,
      explanation: 'Grease contaminates paper recycling. Tear off and recycle the clean top half; put the greasy part in compost or general waste.',
    ),
    QuizQuestion(
      question: 'What should you do with a plastic bottle before recycling?',
      options: ['Crush it with the cap on', 'Empty, rinse, and put the cap back on', 'Leave it full', 'Burn it'],
      correctIndex: 1,
      explanation: 'Emptying and rinsing prevents contamination, and keeping the cap on ensures it doesn\'t get lost in the sorting process.',
    ),
    QuizQuestion(
      question: 'Are coffee cups (like from Starbucks) recyclable in standard paper bins?',
      options: ['Yes', 'No, they have a plastic lining', 'Only the lid', 'Yes, if washed'],
      correctIndex: 1,
      explanation: 'Most hot paper cups have a polyethylene lining to make them waterproof, making them unrecyclable in standard paper facilities.',
    ),
    QuizQuestion(
      question: 'How should you dispose of batteries?',
      options: ['In the general bin', 'In the recycling bin', 'At a dedicated battery drop-off', 'In the compost'],
      correctIndex: 2,
      explanation: 'Batteries contain hazardous chemicals and can start fires in bins. They must go to a dedicated e-waste or battery collection point.',
    ),
    QuizQuestion(
      question: 'Which of the following is NOT recyclable?',
      options: ['Aluminum foil (clean and scrunched)', 'Glass jars', 'Receipts (thermal paper)', 'Cardboard boxes'],
      correctIndex: 2,
      explanation: 'Receipts are often printed on thermal paper, which contains BPA or BPS chemicals and cannot be recycled.',
    ),
    QuizQuestion(
      question: 'How many times can glass be recycled?',
      options: ['Once', '5 times', '100 times', 'Endlessly'],
      correctIndex: 3,
      explanation: 'Glass is endlessly recyclable without loss in quality or purity.',
    ),
    QuizQuestion(
      question: 'What is "wish-cycling"?',
      options: ['Wishing for more recycling bins', 'Recycling things you hope are recyclable, causing contamination', 'Recycling on a bicycle', 'A new type of plastic'],
      correctIndex: 1,
      explanation: 'Wish-cycling is tossing questionable items into the recycling bin hoping they get recycled, which actually slows down sorting and ruins good recyclables.',
    ),
    QuizQuestion(
      question: 'Can you recycle wrapping paper?',
      options: ['Always', 'Never', 'Only if it passes the "scrunch test" (no glitter/foil)', 'Only if it has tape on it'],
      correctIndex: 2,
      explanation: 'If wrapping paper stays scrunched in a ball and has no glitter or metallic foil, it can usually be recycled.',
    ),
    QuizQuestion(
      question: 'What should you do with plastic supermarket carrier bags?',
      options: ['Put them in the home recycling bin', 'Throw them in general waste', 'Take them to a supermarket drop-off point', 'Bury them'],
      correctIndex: 2,
      explanation: 'Thin plastic film tangles recycling machinery. It should be taken to dedicated drop-off points at supermarkets.',
    ),
  ];
}
