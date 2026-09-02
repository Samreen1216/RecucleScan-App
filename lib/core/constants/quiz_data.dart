import '../models/quiz_question.dart';

class QuizData {
  static const List<QuizQuestion> questions = [
    QuizQuestion(
      question: 'Which of these plastics is generally easiest to recycle?',
      options: ['PET (#1)', 'PVC (#3)', 'Polystyrene (#6)', 'Polycarbonate (#7)'],
      correctIndex: 0,
      explanation: 'PET (Polyethylene Terephthalate), often used for water and soda bottles, is the most widely accepted and recycled plastic globally.',
    ),
    QuizQuestion(
      question: 'Can you recycle a greasy pizza box?',
      options: ['Yes, the whole thing', 'No, not at all', 'Only the clean top half', 'Yes, if you wash it'],
      correctIndex: 2,
      explanation: 'Grease and food oils contaminate paper pulp. Tear off and recycle the clean top half; put the greasy part in compost or general waste.',
    ),
    QuizQuestion(
      question: 'What should you do with a plastic bottle before recycling?',
      options: ['Crush it with the cap on', 'Empty, rinse, and put the cap back on', 'Leave it full', 'Burn it'],
      correctIndex: 1,
      explanation: 'Emptying and rinsing prevents liquid contamination, and keeping the cap on prevents small pieces from falling through sorting screens.',
    ),
    QuizQuestion(
      question: 'Are coffee cups (like from Starbucks) recyclable in standard paper bins?',
      options: ['Yes, fully recyclable', 'No, they have a waterproof plastic lining', 'Only the paper cup body', 'Yes, if rinsed with water'],
      correctIndex: 1,
      explanation: 'Most takeaway hot paper cups have a thin polyethylene plastic lining to prevent leaking, making them unrecyclable in standard paper recycling.',
    ),
    QuizQuestion(
      question: 'How should you dispose of batteries?',
      options: ['In the general bin', 'In the regular recycling bin', 'At a dedicated battery or e-waste drop-off point', 'In the food waste bin'],
      correctIndex: 2,
      explanation: 'Batteries contain heavy metals and can ignite fires in collection trucks and recycling facilities. They must go to dedicated battery drop-off points.',
    ),
    QuizQuestion(
      question: 'Which of the following is NOT recyclable in curbside bins?',
      options: ['Clean aluminum foil', 'Glass condiment jars', 'Receipts printed on thermal paper', 'Flattened cardboard boxes'],
      correctIndex: 2,
      explanation: 'Receipts are printed on thermal paper coated with BPA or BPS chemicals, which can contaminate recycled paper batches.',
    ),
    QuizQuestion(
      question: 'How many times can glass and aluminium be recycled?',
      options: ['Once or twice', 'Up to 7 times', 'Around 50 times', 'Endlessly without loss of quality'],
      correctIndex: 3,
      explanation: 'Both glass and aluminium can be melted down and recycled indefinitely without losing structural integrity or purity.',
    ),
    QuizQuestion(
      question: 'What is "wish-cycling"?',
      options: ['Wishing for more recycling bins', 'Tossing non-recyclables in the bin hoping they get recycled', 'Recycling materials on a bicycle', 'A new bioplastic material'],
      correctIndex: 1,
      explanation: 'Wish-cycling is putting non-recyclable items into recycling bins hoping they will be recycled, which actually clogs machinery and contaminates entire batches.',
    ),
    QuizQuestion(
      question: 'Can you recycle wrapping paper?',
      options: ['Always, any type', 'Never', 'Only if it passes the scrunch test (no glitter or foil)', 'Only if coated with plastic'],
      correctIndex: 2,
      explanation: 'If wrapping paper stays scrunched into a tight ball without springing back and has no metallic foil or glitter, it can usually be recycled.',
    ),
    QuizQuestion(
      question: 'What should you do with plastic supermarket shopping carrier bags?',
      options: ['Put them in the home recycling bin', 'Tie them together in the paper bin', 'Take them to a supermarket plastic bag drop-off point', 'Burn them in your garden'],
      correctIndex: 2,
      explanation: 'Thin flexible plastic film wraps around spinning gears in sorting facilities. Supermarkets provide dedicated collection bins for soft plastics.',
    ),
    QuizQuestion(
      question: 'Why can broken window glass or drinking glasses NOT go into the glass recycling bin?',
      options: ['They have a different melting point and chemical composition', 'They are too sharp to pick up', 'They contain harmful bacteria', 'They are too heavy for recycling trucks'],
      correctIndex: 0,
      explanation: 'Window panes, mirrors, Pyrex, and drinking glasses are treated with chemicals that raise their melting temperature, ruining container glass batches.',
    ),
    QuizQuestion(
      question: 'How much energy is saved by recycling an aluminium can compared to making a new one from raw ore?',
      options: ['About 10%', 'About 30%', 'About 60%', 'Up to 95%'],
      correctIndex: 3,
      explanation: 'Recycling aluminium requires 95% less energy than extracting and refining new aluminium from bauxite ore.',
    ),
    QuizQuestion(
      question: 'Can aerosol spray cans (like deodorant or hairspray) be recycled?',
      options: ['Yes, as long as they are completely empty', 'No, never under any circumstances', 'Only if punctured with a nail', 'Only if plastic cap is glued on'],
      correctIndex: 0,
      explanation: 'Aerosol cans made of steel or aluminium are recyclable once completely empty. Never pierce or flatten pressurized aerosol cans.',
    ),
    QuizQuestion(
      question: 'What is the best way to recycle old electronic devices like phones and laptops?',
      options: ['Throw them in the general waste bin', 'Place them in the glass recycling bin', 'Wipe your data and take them to an authorized e-waste recycler or trade-in', 'Bury them in garden soil'],
      correctIndex: 2,
      explanation: 'Electronics contain precious metals (gold, copper, silver) as well as hazardous substances. Always wipe personal data and use certified e-waste recyclers.',
    ),
    QuizQuestion(
      question: 'Are polystyrene/Styrofoam takeaway food containers accepted in standard curbside recycling?',
      options: ['Yes, always', 'No, they are #6 plastic and rarely recycled curbside', 'Yes, if melted with hot water', 'Only if white in colour'],
      correctIndex: 1,
      explanation: 'Expanded Polystyrene (EPS #6) is 95% air and easily breaks into microplastic beads that contaminate sorting facilities.',
    ),
    QuizQuestion(
      question: 'Why is composting organic food waste beneficial for the planet?',
      options: ['It reduces methane emissions from landfills and enriches soil', 'It makes plastic decompose faster', 'It turns food scraps into electricity instantly', 'It stops all rain runoff'],
      correctIndex: 0,
      explanation: 'When food rots in landfills without oxygen, it generates potent methane gas. Composting aerates the waste and creates nutrient-rich soil.',
    ),
    QuizQuestion(
      question: 'What should you do with leftover cooking oil after deep frying?',
      options: ['Pour it down the kitchen sink drain', 'Pour it into the toilet', 'Let it cool and pour into a sealed container for waste or bio-fuel collection', 'Pour it into the garden grass'],
      correctIndex: 2,
      explanation: 'Pouring oil down drains creates massive "fatbergs" that block sewer systems. Collect it in a jar for council disposal or bio-fuel recycling.',
    ),
    QuizQuestion(
      question: 'Are shredded paper strips easily recyclable in standard recycling sorting bins?',
      options: ['Yes, easier than large sheets', 'No, short fibres fall through sorting screens and cannot be made into high-grade paper', 'Yes, only in compost bins', 'Only if glued back together'],
      correctIndex: 1,
      explanation: 'Shredding destroys the long cellulose fibres in paper. Many municipal facilities cannot catch loose shreds unless contained in paper bags or composted.',
    ),
    QuizQuestion(
      question: 'What does "Upcycling" mean?',
      options: ['Throwing items higher into bins', 'Transforming old or unwanted items into new products of higher quality or value', 'Recycling on an electric bicycle', 'Buying only imported goods'],
      correctIndex: 1,
      explanation: 'Upcycling is the creative reuse of byproduct or discarded materials to create a product of higher quality, beauty, or environmental value.',
    ),
    QuizQuestion(
      question: 'What should you do with old clothing and textiles that are in good condition?',
      options: ['Put them in the organic food waste bin', 'Donate them to charity, thrift shops, or textile recycling collection points', 'Throw them in the plastic recycling bin', 'Burn them'],
      correctIndex: 1,
      explanation: 'Textiles do not belong in standard recycling bins where they tangle machines. Donating prolongs their lifecycle and reduces textile landfill waste.',
    ),
  ];

  /// Returns a shuffled list of non-repeating questions for a fresh quiz session.
  static List<QuizQuestion> getRandomQuestions({int count = 5}) {
    final pool = List<QuizQuestion>.from(questions)..shuffle();
    return pool.take(count.clamp(1, pool.length)).toList();
  }
}
