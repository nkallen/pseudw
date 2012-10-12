DROP TABLE morphemes;
DROP TABLE lexemes;
CREATE TABLE IF NOT EXISTS lexemes (
  lemma VARCHAR(128) PRIMARY KEY,
  translation TEXT);

DROP TYPE part_of_speech;
CREATE TYPE part_of_speech AS ENUM('participle', 'verb', 'noun', 'exclamation', 'preposition', 'adjective', 'adverb', 'pronoun', 'particle', 'conjunction', 'adverbial', 'article', 'irregular', 'numeral');
DROP TYPE gender;
CREATE TYPE gender AS ENUM('masculine', 'feminine', 'neuter');
DROP TYPE number;
CREATE TYPE number AS ENUM('singular', 'dual', 'plural');
DROP TYPE "case";
CREATE TYPE "case" AS ENUM('nominative', 'vocative', 'genitive', 'dative', 'accusative');
DROP TYPE tense;
CREATE TYPE tense AS ENUM('present', 'imperfect', 'future', 'aorist', 'perfect', 'pluperfect', 'futurePerfect');
DROP TYPE voice;
CREATE TYPE voice AS ENUM('active', 'middle', 'passive', 'middlePassive');
DROP TYPE mood;
CREATE TYPE mood AS ENUM('indicative', 'imperative', 'optative', 'subjunctive', 'infinitive');
DROP TYPE person;
CREATE TYPE person AS ENUM('1st', '2nd', '3rd');

CREATE TABLE IF NOT EXISTS morphemes (
  lemma VARCHAR(128),
  form VARCHAR(128),
  part_of_speech part_of_speech,
  gender gender,
  number number,
  "case" "case",
  tense tense,
  voice voice,
  mood mood,
  person person,
  UNIQUE (lemma, part_of_speech, tense, voice, gender, number, "case", person, mood, form));