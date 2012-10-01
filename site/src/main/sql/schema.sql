CREATE TABLE IF NOT EXISTS morphemes (
  id INTEGER AUTO_INCREMENT PRIMARY KEY,
  `lemma` VARCHAR(63) CHARACTER SET utf8,
  `form` VARCHAR(63) CHARACTER SET utf8,
  `part_of_speech` ENUM('participle', 'verb', 'noun', 'exclamation', 'preposition', 'adjective', 'adverb', 'pronoun', 'particle', 'conjunction', 'adverbial', 'article', 'irregular', 'numeral'),
  gender ENUM('masculine', 'feminine', 'neuter'),
  `number` ENUM('singular', 'dual', 'plural'),
  `case` ENUM('nominative', 'vocative', 'genitive', 'dative', 'accusative'),
  tense ENUM('present', 'imperfect', 'future', 'aorist', 'perfect', 'pluperfect', 'future-perfect', 'infinitive'),
  voice ENUM('active', 'middle', 'passive', 'middle-passive'),
  mood ENUM('indicative', 'imperative', 'optative', 'subjunctive'),
  person ENUM('1st', '2nd', '3rd'),
  UNIQUE (`lemma`, `part_of_speech`, `tense`, `voice`, `person`, `mood`, `gender`, `number`, `case`, `form`), -- useful for verb lookup
  INDEX (`form`), -- useful for lemmatization
  INDEX (`lemma`, `part_of_speech`, `gender`, `number`, `case`)); -- useful for noun and participle lookup