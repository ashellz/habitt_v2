// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get accentColor => 'Akzentfarbe';

  @override
  String get add => 'Hinzufügen';

  @override
  String get addANewAmountLabelYouCanReuseLater =>
      'Füge eine neue Mengeneinheit hinzu, die du später wiederverwenden kannst.';

  @override
  String get addANotification => 'Benachrichtigung hinzufügen';

  @override
  String get addHabit => 'Gewohnheit hinzufügen';

  @override
  String get addMoreOptions => 'Mehr Optionen hinzufügen';

  @override
  String get afternoon => 'Nachmittag';

  @override
  String get all => 'Alle';

  @override
  String get allChangesYouMadeWillBeDiscarded =>
      'Alle Änderungen, die du vorgenommen hast, werden verworfen.';

  @override
  String get allChangesYouveMadeNowWillBeReset =>
      'Alle Änderungen, die du gerade vorgenommen hast, werden zurückgesetzt.';

  @override
  String get habitConfigDiscardDesc =>
      'Alle Einstellungen, die du für diese Gewohnheit vorgenommen hast, werden verworfen.';

  @override
  String get amount => 'Menge';

  @override
  String get amountName => 'Name der Menge';

  @override
  String get anyTime => 'Jederzeit';

  @override
  String get deleteHabitDesc =>
      'Bist du sicher, dass du diese Gewohnheit löschen willst?';

  @override
  String get optOutOfBackup => 'Backup deaktivieren?';

  @override
  String get backupData => 'Daten sichern';

  @override
  String get backupDataDownloadedFromCloud =>
      'Backup-Daten aus der Cloud heruntergeladen.';

  @override
  String get backupDataFailedToDownloadFromCloud =>
      'Sicherungsdaten konnten nicht aus der Cloud heruntergeladen werden.';

  @override
  String get backupPassphrase => 'Backup-Passphrase';

  @override
  String get calendar => 'Kalender';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get changeAColorThemeForYourInterface =>
      'Ändere das Farbschema deiner Oberfläche';

  @override
  String get changesSaved => 'Änderungen gespeichert!';

  @override
  String get chooseHowColorfulTheUiShouldBe =>
      'Wähle, wie bunt die Oberfläche sein soll';

  @override
  String get clear => 'Leeren';

  @override
  String get clearSelectedDays => 'Ausgewählte Tage löschen';

  @override
  String get colorfulInterface => 'Bunte Oberfläche';

  @override
  String get complete => 'Abschließen';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String completedHabitFoundHabitscompletedTotal(Object habitsCompleted) {
    return 'Abgeschlossene Gewohnheit gefunden, $habitsCompleted insgesamt';
  }

  @override
  String get completedHabits => 'Abgeschlossene Gewohnheiten:';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get confirmDeletion => 'Löschen bestätigen';

  @override
  String get connectToGoogle => 'Mit Google verbinden';

  @override
  String get controlWhenAndHowYouGetNotifiedAboutYourHabits =>
      'Lege fest, wann und wie du über deine Gewohnheiten benachrichtigt wirst.';

  @override
  String get createAmountLabel => 'Mengeneinheit erstellen';

  @override
  String get custom => 'Benutzerdefiniert';

  @override
  String get daily => 'Täglich';

  @override
  String get darkMode => 'Dunkler Modus';

  @override
  String get dateJoinedIsNull => 'Datum verbunden ist null';

  @override
  String get datejoined => 'dateJoined';

  @override
  String get dayEntryIsNull => 'Tageseintrag ist null';

  @override
  String get decrementingHabitAmount => 'Verringern der Gewohnheitsmenge';

  @override
  String get defaultlabel => ', defaultLabel:';

  @override
  String get delete => 'Löschen';

  @override
  String deleteLabel(Object label) {
    return '\'$label\' löschen?';
  }

  @override
  String get deleteNotification => 'Benachrichtigung löschen?';

  @override
  String get discard => 'Verwerfen';

  @override
  String get discardChanges => 'Änderungen verwerfen?';

  @override
  String get done => 'Erledigt';

  @override
  String get driveApiReturnedNullFilesList =>
      'Die Laufwerk-API hat eine Liste mit Null-Dateien zurückgegeben';

  @override
  String get duration => 'Dauer';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editHabit => 'Gewohnheit bearbeiten';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get enable => 'Aktivieren';

  @override
  String get endTime => 'Endzeit';

  @override
  String enterHabitNameToConfirmDeletion(Object habitName) {
    return 'Gib \'$habitName\' ein, um das Löschen zu bestätigen';
  }

  @override
  String get enterPassphrase => 'Passphrase eingeben';

  @override
  String get enterYourAmount => 'Gib deine Menge ein';

  @override
  String get enterYourDuration => 'Gib deine Dauer ein';

  @override
  String get enterYourExistingBackupPassphraseToAccessYourData =>
      'Gib deine bestehende Backup-Passphrase ein, um auf deine Daten zuzugreifen.';

  @override
  String get evening => 'Abend';

  @override
  String get exit => 'Beenden';

  @override
  String get exitWithoutSaving => 'Beenden ohne zu speichern?';

  @override
  String get fetchOffers => 'Angebote abrufen';

  @override
  String get fri => 'Fr';

  @override
  String get from => 'Von';

  @override
  String get getRemindedAboutYourHabit =>
      'Lass dich an deine Gewohnheit erinnern';

  @override
  String get glassFeel => 'Glas-Effekt';

  @override
  String get goodAfternoon => 'Guten Tag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get morning => 'Morgen';

  @override
  String get goodMorningTimeToCheckYourHabits =>
      'Guten Morgen! Zeit, deine Gewohnheiten zu checken';

  @override
  String get goodToSeeYou => 'Schön, dich zu sehen';

  @override
  String get guest => 'Gast';

  @override
  String get habit => 'Gewohnheit';

  @override
  String get habitAdded => 'Gewohnheit hinzugefügt!';

  @override
  String get habitDeleted => 'Gewohnheit gelöscht!';

  @override
  String get habitIsNotInABoxSkippingSave =>
      'Gewohnheit ist nicht in einer Box, überspringt save()';

  @override
  String get habitName => 'Name der Gewohnheit';

  @override
  String get habitNotFoundInDayEntry =>
      'Gewohnheit nicht im Tageseintrag gefunden';

  @override
  String get habits => 'Gewohnheiten';

  @override
  String get hello => 'Hallo';

  @override
  String get helloThere => 'Hallo du';

  @override
  String get hi => 'Hallo';

  @override
  String get hiThere => 'Hi du';

  @override
  String get home => 'Startseite';

  @override
  String get hours => 'Stunden';

  @override
  String get howAreYou => 'Wie geht\'s dir';

  @override
  String get howLongWillThisHabitTake =>
      'Wie lange wird diese Gewohnheit dauern?';

  @override
  String get howMuchDidYouCompleteToday => 'Wie viel hast du heute geschafft?';

  @override
  String get howMuchTimeDidYouSpendOnThisHabitToday =>
      'Wie viel Zeit hast du heute mit dieser Gewohnheit verbracht?';

  @override
  String get howOftenWouldYouLikeToDoThisHabit =>
      'Wie oft möchtest du diese Gewohnheit ausführen?';

  @override
  String get ifCheckedHabitWontCountForThePerfectDaysStreak =>
      'Wenn aktiviert, zählt die Gewohnheit nicht für den „Perfekte-Tage-Streak“.';

  @override
  String get incorrectPassphrase => 'Falsche Passphrase.';

  @override
  String get initialProgressValuesLoadedForAllDays =>
      'Anfangsfortschrittswerte für alle Tage geladen';

  @override
  String get insightStrengthApplyDecrease => 'Senkung übernehmen';

  @override
  String get insightStrengthApplyIncrease => 'Erhöhung übernehmen';

  @override
  String insightStrengthIncreaseBrushTeeth(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut beim Zähneputzen. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit beim Zähneputzen. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Dein Zähneputzen läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass beim Zähneputzen. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus beim Zähneputzen. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseDrinkWater(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut beim Wassertrinken. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit beim Wassertrinken. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Dein Wassertrinken läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass beim Wassertrinken. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus beim Wassertrinken. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseGeneric(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Deine Beständigkeit ist stark. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Du hast diese Gewohnheit gut im Griff. Die Stärke liegt stabil bei $strength%. Erhöhe das Ziel von $fromValue auf $toValue für mehr Wachstum.|Der Schwung stimmt. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um aufzusteigen.|Du hast eine verlässliche Basis aufgebaut. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue und verbessere dich weiter.|Starke Beständigkeit in letzter Zeit. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, damit dein Fortschritt weiter steigt.';
  }

  @override
  String insightStrengthIncreaseGoToBedEarly(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut beim frühen Schlafengehen. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit beim frühen Schlafengehen. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Dein frühes Schlafengehen läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass beim frühen Schlafengehen. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus beim frühen Schlafengehen. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseGym(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut bei deiner Gym-Routine. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit bei deiner Gym-Routine. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Deine Gym-Routine läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass bei deiner Gym-Routine. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus bei deiner Gym-Routine. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseNutrition(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut bei deinem Ernährungsplan. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit bei deinem Ernährungsplan. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Dein Ernährungsplan läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass bei deinem Ernährungsplan. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus bei deinem Ernährungsplan. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreasePraying(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut beim regelmäßigen Beten. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit beim regelmäßigen Beten. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Dein regelmäßiges Beten läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass beim regelmäßigen Beten. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus beim regelmäßigen Beten. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseProductivitySession(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut bei deinen Produktivitätssessions. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit bei deinen Produktivitätssessions. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Deine Fokus-Routine läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass bei deinen Produktivitätssessions. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus bei deinen Produktivitätssessions. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseRead(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut bei deiner Lesegewohnheit. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit bei deiner Lesegewohnheit. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Deine Lesegewohnheit läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass bei deiner Lesegewohnheit. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus bei deiner Lesegewohnheit. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseResearch(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut bei deiner Recherche. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit bei deiner Recherche. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Deine Recherche-Gewohnheit läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass bei deiner Recherche. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus bei deiner Recherche. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseRunning(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut bei deiner Lauf-Routine. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit bei deiner Lauf-Routine. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Deine Lauf-Routine läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass bei deiner Lauf-Routine. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus bei deiner Lauf-Routine. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseShower(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut bei deiner Dusch-Routine. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit bei deiner Dusch-Routine. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Deine Dusch-Routine läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass bei deiner Dusch-Routine. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus bei deiner Dusch-Routine. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseSkinCare(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut bei deiner Hautpflege. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit bei deiner Hautpflege. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Deine Hautpflege-Routine läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass bei deiner Hautpflege. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus bei deiner Hautpflege. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseStudying(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut beim Lernen. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit beim Lernen. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Deine Lerngewohnheit läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass beim Lernen. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus beim Lernen. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseTargetTitle(Object habitName) {
    return 'Ziel für $habitName erhöhen';
  }

  @override
  String insightStrengthIncreaseWakeUpEarly(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut beim frühen Aufstehen. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit beim frühen Aufstehen. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Dein frühes Aufstehen läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass beim frühen Aufstehen. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus beim frühen Aufstehen. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseWalk(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut bei deinen Spaziergängen. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit bei deinen Spaziergängen. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Deine Spazier-Routine läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass bei deinen Spaziergängen. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus bei deinen Spaziergängen. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthIncreaseWork(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du machst das richtig gut bei deiner Arbeit. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter zu wachsen.|Starke Beständigkeit bei deiner Arbeit. Die Stärke liegt stabil bei $strength%. Erhöhe dein Ziel von $fromValue auf $toValue und halte den Schwung hoch.|Deine Arbeitsgewohnheit läuft richtig gut. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue für das nächste Level.|Auf dich ist Verlass bei deiner Arbeit. Die Stärke liegt stabil bei $strength%. Geh von $fromValue auf $toValue, um dich weiter zu verbessern.|Toller Rhythmus bei deiner Arbeit. Die Stärke liegt stabil bei $strength%. Empfohlenes Ziel: $fromValue -> $toValue, um weiter voranzukommen.';
  }

  @override
  String insightStrengthKeepPushingTitle(Object habitName) {
    return 'Bleib dran an „$habitName“';
  }

  @override
  String insightStrengthLowerTargetTitle(Object habitName) {
    return 'Dein Ziel für „$habitName“ ist vielleicht zu hoch';
  }

  @override
  String get insightStrengthStartSmallType1BrushTeeth =>
      'Dein Zähneputzen gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist beim Zähneputzen aus dem Takt geraten. Putz dir heute die Zähne und schütze die Gewohnheit.|Dein Zähneputzen verliert an Schwung. Halte ihn am Leben: putz dir heute die Zähne.|Bleib beim Zähneputzen dran und werde nicht nachlässig. Putz dir heute die Zähne.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1DrinkWater =>
      'Dein Wassertrinken gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist beim Wassertrinken aus dem Takt geraten. Trink heute genug Wasser und schütze die Gewohnheit.|Dein Wassertrinken verliert an Schwung. Halte ihn am Leben: trink heute genug Wasser.|Bleib beim Wassertrinken dran und werde nicht nachlässig. Trink heute genug Wasser.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Generic =>
      'Du hast diese Gewohnheit aus einem Grund hinzugefügt. Lass sie jetzt nicht schleifen.|Diese Gewohnheit verliert an Schwung. Zieh sie heute durch und halte sie am Leben.|Du fällst bei dieser Gewohnheit zurück. Konzentrier dich und erledige sie.|Verhandle hier nicht mit der Faulheit. Schütze diese Gewohnheit heute.|Du bist zu weit gekommen, um diese Gewohnheit abdriften zu lassen. Bleib heute dran.';

  @override
  String get insightStrengthStartSmallType1GoToBedEarly =>
      'Dein frühes Schlafengehen gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist beim frühen Schlafengehen aus dem Takt geraten. Geh heute Abend pünktlich ins Bett und schütze die Gewohnheit.|Dein frühes Schlafengehen verliert an Schwung. Halte ihn am Leben: geh heute Abend pünktlich ins Bett.|Bleib beim frühen Schlafengehen dran und werde nicht nachlässig. Geh heute Abend pünktlich ins Bett.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Gym =>
      'Deine Gym-Routine gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deiner Gym-Routine aus dem Takt geraten. Geh heute ins Gym und schütze die Gewohnheit.|Deine Gym-Routine verliert an Schwung. Halte ihn am Leben: geh heute ins Gym.|Bleib bei deiner Gym-Routine dran und werde nicht nachlässig. Geh heute ins Gym.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Medications =>
      'Deine Medikamenten-Routine gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deinen Medikamenten aus dem Takt geraten. Nimm heute deine Medikamente pünktlich und schütze die Gewohnheit.|Deine Medikamenten-Routine verliert an Schwung. Halte ihn am Leben: nimm heute deine Medikamente pünktlich.|Bleib bei deinen Medikamenten dran und werde nicht nachlässig. Nimm heute deine Medikamente pünktlich.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Nutrition =>
      'Dein Ernährungsplan gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deinem Ernährungsplan aus dem Takt geraten. Halte dich heute an deinen Plan und schütze die Gewohnheit.|Dein Ernährungsplan verliert an Schwung. Halte ihn am Leben: halte dich heute an deinen Plan.|Bleib bei deinem Ernährungsplan dran und werde nicht nachlässig. Halte dich heute an deinen Plan.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Praying =>
      'Dein regelmäßiges Beten gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist beim regelmäßigen Beten aus dem Takt geraten. Nimm dir heute Zeit zum Beten und schütze die Gewohnheit.|Dein regelmäßiges Beten verliert an Schwung. Halte ihn am Leben: nimm dir heute Zeit zum Beten.|Bleib beim regelmäßigen Beten dran und werde nicht nachlässig. Nimm dir heute Zeit zum Beten.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1ProductivitySession =>
      'Deine Fokus-Routine gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deinen Produktivitätssessions aus dem Takt geraten. Mach heute eine konzentrierte Session und schütze die Gewohnheit.|Deine Fokus-Routine verliert an Schwung. Halte ihn am Leben: mach heute eine konzentrierte Session.|Bleib bei deinen Produktivitätssessions dran und werde nicht nachlässig. Mach heute eine konzentrierte Session.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Read =>
      'Deine Lesegewohnheit gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deiner Lesegewohnheit aus dem Takt geraten. Lies heute ein paar Seiten und schütze die Gewohnheit.|Deine Lesegewohnheit verliert an Schwung. Halte ihn am Leben: lies heute ein paar Seiten.|Bleib bei deiner Lesegewohnheit dran und werde nicht nachlässig. Lies heute ein paar Seiten.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Research =>
      'Deine Recherche-Gewohnheit gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deiner Recherche aus dem Takt geraten. Recherchiere heute ein bisschen und schütze die Gewohnheit.|Deine Recherche-Gewohnheit verliert an Schwung. Halte ihn am Leben: recherchiere heute ein bisschen.|Bleib bei deiner Recherche dran und werde nicht nachlässig. Recherchiere heute ein bisschen.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Running =>
      'Deine Lauf-Routine gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deiner Lauf-Routine aus dem Takt geraten. Geh heute laufen und schütze die Gewohnheit.|Deine Lauf-Routine verliert an Schwung. Halte ihn am Leben: geh heute laufen.|Bleib bei deiner Lauf-Routine dran und werde nicht nachlässig. Geh heute laufen.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Shower =>
      'Deine Dusch-Routine gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deiner Dusch-Routine aus dem Takt geraten. Geh heute duschen und schütze die Gewohnheit.|Deine Dusch-Routine verliert an Schwung. Halte ihn am Leben: geh heute duschen.|Bleib bei deiner Dusch-Routine dran und werde nicht nachlässig. Geh heute duschen.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1SkinCare =>
      'Deine Hautpflege-Routine gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deiner Hautpflege aus dem Takt geraten. Mach heute deine Hautpflege und schütze die Gewohnheit.|Deine Hautpflege-Routine verliert an Schwung. Halte ihn am Leben: mach heute deine Hautpflege.|Bleib bei deiner Hautpflege dran und werde nicht nachlässig. Mach heute deine Hautpflege.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Studying =>
      'Deine Lerngewohnheit gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist beim Lernen aus dem Takt geraten. Lern heute ein Stück und schütze die Gewohnheit.|Deine Lerngewohnheit verliert an Schwung. Halte ihn am Leben: lern heute ein Stück.|Bleib beim Lernen dran und werde nicht nachlässig. Lern heute ein Stück.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1WakeUpEarly =>
      'Dein frühes Aufstehen gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist beim frühen Aufstehen aus dem Takt geraten. Stell dir den Wecker und steh morgen pünktlich auf und schütze die Gewohnheit.|Dein frühes Aufstehen verliert an Schwung. Halte ihn am Leben: stell dir den Wecker und steh morgen pünktlich auf.|Bleib beim frühen Aufstehen dran und werde nicht nachlässig. Stell dir den Wecker und steh morgen pünktlich auf.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Walk =>
      'Deine Spazier-Routine gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deinen Spaziergängen aus dem Takt geraten. Geh heute spazieren und schütze die Gewohnheit.|Deine Spazier-Routine verliert an Schwung. Halte ihn am Leben: geh heute spazieren.|Bleib bei deinen Spaziergängen dran und werde nicht nachlässig. Geh heute spazieren.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String get insightStrengthStartSmallType1Work =>
      'Deine Arbeitsgewohnheit gerät ins Wanken. Lass diese Routine jetzt nicht fallen.|Du bist bei deiner Arbeit aus dem Takt geraten. Erledige heute etwas Sinnvolles und schütze die Gewohnheit.|Deine Arbeitsgewohnheit verliert an Schwung. Halte ihn am Leben: erledige heute etwas Sinnvolles.|Bleib bei deiner Arbeit dran und werde nicht nachlässig. Erledige heute etwas Sinnvolles.|Du hattest einen Grund, damit anzufangen. Bleib diszipliniert und lass es nicht schleifen.';

  @override
  String insightStrengthStartSmallType2BrushTeeth(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst beim Zähneputzen zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Dein Zähneputzen hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit beim Zähneputzen hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du beim Zähneputzen dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Dein Zähneputzen braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2DrinkWater(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst beim Wassertrinken zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Dein Wassertrinken hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit beim Wassertrinken hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du beim Wassertrinken dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Dein Wassertrinken braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Generic(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Die Beständigkeit bei dieser Gewohnheit hat nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um dich wieder zu stabilisieren.|Du bist zuletzt aus dem Takt geraten. Die Stärke ist um $drop% gesunken. Versuch diese Anpassung: $fromValue -> $toValue, um deinen Rhythmus wiederzufinden.|Deine Leistung lässt zuletzt nach. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder auf Kurs zu kommen.|Diese Gewohnheit braucht vorerst ein leichteres Ziel. Die Stärke ist um $drop% gesunken. Geh von $fromValue auf $toValue, um beständiger zu werden.|Deine Gewohnheit ist zuletzt schwächer geworden. Die Stärke ist um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit du dranbleiben kannst.';
  }

  @override
  String insightStrengthStartSmallType2GoToBedEarly(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst beim frühen Schlafengehen zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Dein frühes Schlafengehen hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit beim frühen Schlafengehen hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du beim frühen Schlafengehen dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Dein frühes Schlafengehen braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Gym(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deiner Gym-Routine zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Gym-Routine hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deiner Gym-Routine hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deiner Gym-Routine dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Gym-Routine braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Medications(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deinen Medikamenten zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Medikamenten-Routine hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deinen Medikamenten hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deinen Medikamenten dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Medikamenten-Routine braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Nutrition(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deinem Ernährungsplan zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Dein Ernährungsplan hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deinem Ernährungsplan hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deinem Ernährungsplan dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Dein Ernährungsplan braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Praying(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst beim regelmäßigen Beten zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Dein regelmäßiges Beten hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit beim regelmäßigen Beten hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du beim regelmäßigen Beten dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Dein regelmäßiges Beten braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2ProductivitySession(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deinen Produktivitätssessions zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Fokus-Routine hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deinen Produktivitätssessions hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deinen Produktivitätssessions dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Fokus-Routine braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Read(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deiner Lesegewohnheit zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Lesegewohnheit hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deiner Lesegewohnheit hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deiner Lesegewohnheit dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Lesegewohnheit braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Research(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deiner Recherche zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Recherche-Gewohnheit hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deiner Recherche hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deiner Recherche dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Recherche-Gewohnheit braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Running(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deiner Lauf-Routine zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Lauf-Routine hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deiner Lauf-Routine hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deiner Lauf-Routine dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Lauf-Routine braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Shower(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deiner Dusch-Routine zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Dusch-Routine hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deiner Dusch-Routine hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deiner Dusch-Routine dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Dusch-Routine braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2SkinCare(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deiner Hautpflege zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Hautpflege-Routine hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deiner Hautpflege hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deiner Hautpflege dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Hautpflege-Routine braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Studying(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst beim Lernen zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Lerngewohnheit hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit beim Lernen hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du beim Lernen dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Lerngewohnheit braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2WakeUpEarly(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst beim frühen Aufstehen zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Dein frühes Aufstehen hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit beim frühen Aufstehen hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du beim frühen Aufstehen dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Dein frühes Aufstehen braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Walk(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deinen Spaziergängen zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Spazier-Routine hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deinen Spaziergängen hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deinen Spaziergängen dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Spazier-Routine braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String insightStrengthStartSmallType2Work(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Du warst bei deiner Arbeit zuletzt nicht beständig. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, damit die Gewohnheit am Leben bleibt.|Deine Arbeitsgewohnheit hat zuletzt nachgelassen. Die Stärke ist um $drop% gesunken. Setz dein Ziel von $fromValue auf $toValue, um wieder Beständigkeit aufzubauen.|Deine Beständigkeit bei deiner Arbeit hat zuletzt nachgelassen. Die Stärke ist in den letzten Tagen um $drop% gesunken. Empfohlenes Ziel: $fromValue -> $toValue, um wieder in Schwung zu kommen.|Senk das Ziel vorerst, damit du bei deiner Arbeit dranbleibst. Die Stärke ist um $drop% gesunken. Empfohlen: $fromValue -> $toValue.|Deine Arbeitsgewohnheit braucht einen Neustart. Die Stärke ist um $drop% gesunken. Versuch $fromValue -> $toValue, damit diese Gewohnheit lebendig bleibt.';
  }

  @override
  String get invalidTime => 'Ungültige Zeit';

  @override
  String get keepYourDataSafeByBackingItUpToGoogleDrive =>
      'Schütze deine Daten, indem du sie in Google Drive sicherst.';

  @override
  String get label => 'Einheit';

  @override
  String get leaveSetup => 'Einrichtung verlassen?';

  @override
  String get logDuration => 'Dauer protokollieren';

  @override
  String get logProgress => 'Fortschritt protokollieren';

  @override
  String get makesWidgetsLookMoreGlassy =>
      'Lässt Widgets mehr nach Glas aussehen';

  @override
  String get manageYourNotificationPreferences =>
      'Verwalte deine Benachrichtigungseinstellungen';

  @override
  String get manageYourSubscriptionsAndBillingPlansHere =>
      'Verwalte hier deine Abonnements und Zahlungspläne.';

  @override
  String get manageYourSubscriptionsAndViewPremiumBenefits =>
      'Verwalte deine Abonnements und sieh dir die Premium-Vorteile an';

  @override
  String get midday => 'Mittag';

  @override
  String get middayCheckinTimeForYourHabits =>
      'Mittags-Check-in für deine Gewohnheiten';

  @override
  String get minutes => 'Minuten';

  @override
  String get missingPermissions => 'Fehlende Berechtigungen';

  @override
  String get mon => 'Mo';

  @override
  String get moreOptions => 'Mehr Optionen';

  @override
  String get never => 'Niemals';

  @override
  String get newHabit => 'Neue Gewohnheit';

  @override
  String get noHabitsFoundUsingDefaultCategoryOrder =>
      'Keine Gewohnheiten gefunden, Standardreihenfolge der Kategorien verwendet.';

  @override
  String get noHabitsYet => 'Noch keine Gewohnheiten.';

  @override
  String get noOfferingsAvailable => 'Keine Angebote verfügbar';

  @override
  String get noTag => 'Keine Markierung';

  @override
  String get notCompleted => 'Nicht abgeschlossen';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get notes => 'Anmerkungen';

  @override
  String notificationAmountLabelFocus(Object label, Object target) {
    return 'Dein Ziel heute: $target $label.|Deine Zahl für heute: $target $label. Fang mit einem an.|Heutige Dosis: $target $label. Klares Ziel, einfache Umsetzung.|Heute stehen $target $label an. Du kennst den Rhythmus.|Ziel für heute: $target $label. Ein klares Ziel ist ein starker Anstoß.';
  }

  @override
  String notificationCombinedAmountAlmostDone(
    Object encouragement,
    Object remaining,
  ) {
    return 'Nur noch $remaining – $encouragement.';
  }

  @override
  String get notificationCombinedAmountCompleted =>
      'Ziel schon erreicht, gut gemacht.|Du hast dein heutiges Ziel geschafft, Glückwunsch!|Du hast dein Ziel heute schon erreicht – starke Leistung!|Das Ziel ist schon erfüllt, super!|Du hast dein heutiges Ziel schon erreicht, hervorragende Arbeit!';

  @override
  String notificationCombinedAmountInProgress(
    Object encouragement,
    Object progress,
  ) {
    return 'Du stehst bei $progress – $encouragement.';
  }

  @override
  String notificationCombinedAmountNotStarted(Object encouragement) {
    return 'Fang jetzt an, jeder Schritt zählt – $encouragement.';
  }

  @override
  String notificationCombinedDurationAlmostDone(
    Object encouragement,
    Object remaining,
  ) {
    return 'Nur noch $remaining – $encouragement.';
  }

  @override
  String notificationCombinedDurationCompleted(Object encouragement) {
    return 'Ziel schon erreicht – $encouragement.';
  }

  @override
  String notificationCombinedDurationInProgress(
    Object encouragement,
    Object progress,
  ) {
    return 'Du stehst bei $progress – $encouragement.';
  }

  @override
  String notificationCombinedDurationNotStarted(Object encouragement) {
    return 'Starte jetzt eine kurze Session – $encouragement.';
  }

  @override
  String notificationCombinedFresh(Object days, Object encouragement) {
    return 'Du hast diese Gewohnheit vor $days Tagen begonnen – $encouragement.';
  }

  @override
  String notificationCombinedGeneral(Object encouragement) {
    return '$encouragement.';
  }

  @override
  String notificationCombinedOneOff(Object encouragement, Object period) {
    return 'Verpass heute nicht, es ist deine letzte Chance $period – $encouragement.';
  }

  @override
  String get notificationEncourageBrushTeeth1 =>
      'so bleibt deine Hygiene-Serie stark';

  @override
  String get notificationEncourageBrushTeeth2 =>
      'ein schneller Erfolg schützt deine Routine';

  @override
  String get notificationEncourageBrushTeeth3 =>
      'bleib bei der Grundpflege beständig';

  @override
  String get notificationEncourageDrinkWater1 =>
      'Wasser jetzt unterstützt deinen ganzen Körper';

  @override
  String get notificationEncourageDrinkWater2 =>
      'ein Glas jetzt hält deine Energie stabiler';

  @override
  String get notificationEncourageDrinkWater3 =>
      'kleine Schlucke verbessern deine tägliche Leistung';

  @override
  String get notificationEncourageGeneric1 =>
      'wenn du heute dranbleibst, bleibt die Gewohnheit am Leben';

  @override
  String get notificationEncourageGeneric2 =>
      'ein kleiner Schritt jetzt schützt deinen Schwung';

  @override
  String get notificationEncourageGeneric3 =>
      'Beständigkeit heute macht morgen leichter';

  @override
  String get notificationEncourageGoToBedEarly1 =>
      'ein ruhiger Abend heute macht morgen leichter';

  @override
  String get notificationEncourageGoToBedEarly10 =>
      'diese Entscheidung heute Abend lässt deine ganze Woche besser laufen';

  @override
  String get notificationEncourageGoToBedEarly2 =>
      'früher ins Bett gibt deinem Kopf einen klareren Start';

  @override
  String get notificationEncourageGoToBedEarly3 =>
      'diese Entscheidung heute Abend sorgt für einen besseren Morgen';

  @override
  String get notificationEncourageGoToBedEarly4 =>
      'regelmäßiger Schlaf zahlt sich morgen den ganzen Tag aus';

  @override
  String get notificationEncourageGoToBedEarly5 =>
      'eine ruhige Abendroutine schützt deine Energie';

  @override
  String get notificationEncourageGoToBedEarly6 =>
      'den Tag pünktlich zu beenden hält deinen Rhythmus stabil';

  @override
  String get notificationEncourageGoToBedEarly7 =>
      'besseres Schlaf-Timing ist ein stiller Leistungsvorteil';

  @override
  String get notificationEncourageGoToBedEarly8 =>
      'früher Licht aus hält deine Erholung auf Kurs';

  @override
  String get notificationEncourageGoToBedEarly9 =>
      'ein bisschen Disziplin beim Schlafengehen sorgt für stärkere Morgen';

  @override
  String get notificationEncourageGym1 =>
      'ein Training heute hält deinen Standard hoch';

  @override
  String get notificationEncourageGym2 =>
      'wenn du jetzt gehst, bleibt deine Kraft im Aufwind';

  @override
  String get notificationEncourageGym3 =>
      'die heutige Einheit zahlt sich mit der Zeit aus';

  @override
  String get notificationEncourageMedications1 =>
      'die richtige Zeit schützt deine Gesundheitsroutine';

  @override
  String get notificationEncourageMedications2 =>
      'im Zeitplan zu bleiben hält dich stabil';

  @override
  String get notificationEncourageMedications3 =>
      'dieser Schritt unterstützt dein langfristiges Wohlbefinden';

  @override
  String get notificationEncourageNutrition1 =>
      'eine bewusste Entscheidung jetzt stärkt deine Basis';

  @override
  String get notificationEncourageNutrition2 =>
      'kleine Ernährungserfolge summieren sich schnell';

  @override
  String get notificationEncourageNutrition3 =>
      'Beständigkeit hier verbessert alles andere';

  @override
  String get notificationEncourageProductivitySession1 =>
      'eine konzentrierte Session schützt deine Fokuszeit';

  @override
  String get notificationEncourageProductivitySession2 =>
      'ein sauberer Fokusblock kann deinen Tag verändern';

  @override
  String get notificationEncourageProductivitySession3 =>
      'beständiger Fokus bringt bessere Ergebnisse';

  @override
  String get notificationEncourageRead1 =>
      'ein paar Seiten jetzt halten dich als Leser in Form';

  @override
  String get notificationEncourageRead2 =>
      'tägliches Lesen summiert sich zu echtem Fortschritt';

  @override
  String get notificationEncourageRead3 =>
      'wenn du heute liest, bleibt die Serie am Leben';

  @override
  String get notificationEncourageResearch1 =>
      'eine Erkenntnis heute bringt deine Arbeit voran';

  @override
  String get notificationEncourageResearch2 =>
      'stetiges Forschen sorgt mit der Zeit für Klarheit';

  @override
  String get notificationEncourageResearch3 =>
      'ein festgehaltenes Ergebnis jetzt hält den Schwung';

  @override
  String get notificationEncourageRunning1 =>
      'ein Lauf heute baut Ausdauer auf';

  @override
  String get notificationEncourageRunning2 =>
      'wenn du jetzt läufst, wird deine Basis stärker';

  @override
  String get notificationEncourageRunning3 =>
      'dieser Einsatz hält deine Fitness in Schwung';

  @override
  String get notificationEncourageShower1 =>
      'ein kurzer Reset kann deinen Fokus heben';

  @override
  String get notificationEncourageShower2 =>
      'diese Routine macht dich wach und bereit';

  @override
  String get notificationEncourageShower3 =>
      'ein frischer Neustart hält deinen Tag in Bewegung';

  @override
  String get notificationEncourageSkinCare1 =>
      'ein beständiger Schritt schützt deine Haut';

  @override
  String get notificationEncourageSkinCare2 =>
      'Beständigkeit ist dein Hautpflege-Vorteil';

  @override
  String get notificationEncourageSkinCare3 =>
      'halte deine Routine einfach und zuverlässig';

  @override
  String get notificationEncourageStudying1 =>
      'ein konzentrierter Block jetzt bringt dein Lernen in Schwung';

  @override
  String get notificationEncourageStudying2 =>
      'wenn du heute lernst, wächst dein Wissen weiter';

  @override
  String get notificationEncourageStudying3 =>
      'kleine, regelmäßige Sessions schlagen Pauken';

  @override
  String get notificationEncourageWakeUpEarly1 =>
      'starte deinen Tag mit Absicht';

  @override
  String get notificationEncourageWakeUpEarly2 =>
      'halte deinen Morgenrhythmus beständig';

  @override
  String get notificationEncourageWakeUpEarly3 =>
      'gönn dir einen ruhigeren Start';

  @override
  String get notificationEncourageWalk1 =>
      'ein kurzer Spaziergang reicht, um im Schwung zu bleiben';

  @override
  String get notificationEncourageWalk2 =>
      'Bewegung jetzt hilft deiner Energie und deinem Fokus';

  @override
  String get notificationEncourageWalk3 =>
      'dieser einfache Schritt stärkt deine Beständigkeit';

  @override
  String get notificationEncourageWork1 =>
      'wenn du jetzt anfängst, kommst du richtig voran';

  @override
  String get notificationEncourageWork2 =>
      'ein sinnvoller Schub kann deinen Tag freischalten';

  @override
  String get notificationEncourageWork3 =>
      'beständiges Umsetzen hält deinen Fortschritt sichtbar';

  @override
  String get notificationFallbackGeneric =>
      'Kleine Schritte heute sorgen für langfristigen Schwung.';

  @override
  String get notificationFallbackTitle => 'Gewohnheits-Erinnerung';

  @override
  String get notificationFreshnessBrandNew =>
      'Zeit für deine brandneue Gewohnheit!';

  @override
  String notificationFreshnessEstablishedDays(Object days) {
    return 'Du baust das schon seit $days Tagen auf. Sammle weiter Erfolge.';
  }

  @override
  String notificationFreshnessNewDays(Object days) {
    return 'Du hast vor $days Tagen angefangen. Weiter so!|Tag $days. Die ersten Tage sind das Fundament – starke Arbeit.|Du hast vor $days Tagen angefangen. Jeder einzelne zählt.';
  }

  @override
  String get notificationOptional =>
      'Diese ist heute optional, aber hast du Lust, es zu versuchen?|Hast du noch etwas Zeit übrig?';

  @override
  String get notificationPeriodMonthly => 'diesen Monat';

  @override
  String get notificationPeriodWeekly => 'diese Woche';

  @override
  String get notificationPremadeBrushTeeth =>
      'Ein schneller Hygiene-Erfolg hält deine Routine stark.';

  @override
  String get notificationPremadeDrinkWater =>
      'Trink jetzt etwas und halte deinen Körper in Form.';

  @override
  String get notificationPremadeGoToBedEarly =>
      'Schütze den heutigen Abend, damit der Morgen leichter startet.';

  @override
  String get notificationPremadeGym =>
      'Geh ins Gym für ein solides Training und bleib beständig.';

  @override
  String get notificationPremadeMedications =>
      'Nimm deine Medikamente pünktlich, um deine Gesundheit zu schützen.';

  @override
  String get notificationPremadeNutrition =>
      'Triff jetzt eine bewusste Ernährungsentscheidung.';

  @override
  String get notificationPremadePraying =>
      'Nimm dir jetzt einen ruhigen Moment und finde zu dir.';

  @override
  String get notificationPremadeProductivitySession =>
      'Mach eine konzentrierte Session und schütze deine Fokuszeit.';

  @override
  String get notificationPremadeRead =>
      'Lies jetzt ein bisschen und lass die Beständigkeit den Rest erledigen.';

  @override
  String get notificationPremadeResearch =>
      'Halte eine nützliche Erkenntnis fest und bring deine Recherche voran.';

  @override
  String get notificationPremadeRunning =>
      'Schnür die Schuhe und hol dir heute einen starken Lauf.';

  @override
  String get notificationPremadeShower =>
      'Lade deine Energie mit dieser einfachen Routine neu auf.';

  @override
  String get notificationPremadeSkinCare =>
      'Pflege jetzt deine Haut, um beständig zu bleiben.';

  @override
  String get notificationPremadeStudying =>
      'Starte einen konzentrierten Lernblock und komm beim Lernen in Schwung.';

  @override
  String get notificationPremadeWakeUpEarly =>
      'Ein starker Start in den Tag beginnt mit dieser Entscheidung.';

  @override
  String get notificationPremadeWalk =>
      'Ein kurzer Spaziergang jetzt reicht, um im Schwung zu bleiben.';

  @override
  String get notificationPremadeWork =>
      'Fang mit deiner wichtigsten Aufgabe an und komm in Fahrt.';

  @override
  String notificationProgressAlmostDoneAmount(Object label, Object remaining) {
    return 'Du bist so nah dran. Nur noch $remaining $label.|Noch $remaining $label. Das ist dein Rhythmus – bleib dabei.|Noch $remaining $label. Den Großteil hast du schon geschafft.|Fast geschafft – nur $remaining $label trennen dich vom Ziel.|Du bist $remaining $label von deinem Ziel entfernt. Bring es stark zu Ende.|Die Ziellinie ist nah. Nur noch $remaining $label.';
  }

  @override
  String notificationProgressAlmostDoneDuration(Object remaining) {
    return 'Nur noch $remaining. Bleib noch ein bisschen dran und du bist fertig!|Noch $remaining. Ein kleines bisschen mehr geht immer.|Noch $remaining. Fertig zu werden ist schon Belohnung genug.|Noch $remaining. Du schaffst das!';
  }

  @override
  String notificationProgressCompletedAmount(Object completed, Object label) {
    return 'Du hast schon $completed $label geschafft. Bereit für mehr?|$completed $label erledigt. Der Schwung ist jetzt auf deiner Seite.|$completed $label im Kasten. Deine Gewohnheit wirkt.|Stark – $completed $label geschafft. Lust, noch etwas draufzulegen?';
  }

  @override
  String notificationProgressCompletedDuration(Object completed) {
    return 'Ziel erreicht: $completed schon erledigt.|Zeitziel erreicht: $completed. Du warst da und bist drangeblieben.|$completed konzentrierte Zeit. Erledigt. Das ist echtes Engagement.|Session abgeschlossen: $completed. Deine Beständigkeit ist gerade gewachsen.|$completed eingetragen. Dein zukünftiges Ich wird es dir danken.|Zielzeit erreicht: $completed. Starker, konzentrierter Einsatz.';
  }

  @override
  String notificationProgressInProgressAmount(
    Object completed,
    Object label,
    Object remaining,
    Object target,
  ) {
    return '$completed von $target $label. Ran an die Sache!|Du hast schon $completed $label eingetragen. Guter Start.|Bisher $completed/$target $label. Halte das Tempo.|$completed erledigt, noch $remaining. Du schaffst das.|$completed von $target. Mach weiter.';
  }

  @override
  String notificationProgressInProgressDuration(
    Object completed,
    Object target,
  ) {
    return 'Bisher $completed, dein Ziel ist $target – weiter so!|Den schwersten Teil hast du geschafft – den Anfang. Bleib dran.|Du hast $completed von $target eingetragen. Bleib im Flow.|$completed von $target geschafft. Gut so, mach weiter!';
  }

  @override
  String get notificationProgressNoTracking =>
      'Ein kleiner Schritt jetzt hält diese Gewohnheit am Leben.|Lass diese Gewohnheit nicht verblassen, ein wenig Einsatz jetzt schützt deinen Schwung.|Beständigkeit heute macht morgen leichter. Lust, es zu versuchen?|Vergiss deine Gewohnheit heute nicht!|Ein kleiner Schritt jetzt hält deine Gewohnheit stark.|Hey du! Zeit für deine Gewohnheit!|Ein kleiner Schritt hält die Serie am Leben.|Erledigt ist besser als perfekt. Zieh es durch.|Beständigkeit summiert sich. Jeder Tag zählt.|Deine Gewohnheit ist ein Versprechen an dich selbst. Halte es.|Gleiche Gewohnheit, einen Tag stärker. Bau weiter.|Du brauchst keine Motivation. Fang einfach an.|Sieh es als Geschenk an dein zukünftiges Ich. Los geht\'s!|Du baust etwas Wichtiges auf. Mach weiter.|Zeit für das, was zählt. Das bist du.|Neugierig, was passiert, wenn du nie auslässt?|Die Gewohnheit hat dich erinnert. Was ist dein nächster Zug?|Zeit, deinen Plan umzusetzen.|Reiß die Kette nicht ab. Noch ein Tag.|Du musst nicht perfekt sein. Nur dabei sein.|Kleine Schritte heute = große Ergebnisse morgen.';

  @override
  String notificationProgressNotStartedAmount(Object label) {
    return 'Fang mit nur 1 $label an und komm in Schwung. Ganz einfach!|Du brauchst keine Motivation. Fang einfach an.|Der schwerste Teil ist der Anfang. Du schaffst das!';
  }

  @override
  String get notificationProgressNotStartedDuration =>
      'Starte wenigstens mit einer kurzen Session!|Du brauchst keine Motivation. Fang einfach an.|Der schwerste Teil ist der Anfang. Du schaffst das!|In ein paar Minuten wirst du froh sein, dass du angefangen hast.';

  @override
  String notificationScheduleCustomEveryDays(Object days) {
    return 'Eigener Rhythmus: alle $days Tage. Heute ist einer deiner Tage.|Rhythmus alle $days Tage. Heute ist ein geplanter Tag.|Dein $days-Tage-Zyklus ist heute dran. Zeit zu handeln.|Dein Plan sagt: Heute ist der Tag dieser Gewohnheit. Nutze ihn!|Diese Gewohnheit kommt alle $days Tage. Jetzt bist du dran.|Heute gehört zum Rhythmus dieser Gewohnheit. Bleib dem Muster treu.';
  }

  @override
  String get notificationScheduleDaily =>
      'Dein täglicher Anker wartet. Zieh es durch.|Das tägliche Fenster ist offen. Geh hindurch.|Deine tägliche Praxis wächst leise. Aber sie wächst.|Das ist der tägliche Ruf deiner Gewohnheit. Antworte darauf!';

  @override
  String notificationScheduleMonthlyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  ) {
    return 'Du brauchst diesen Monat noch $remaining ($completed/$target erledigt). Wenn du heute auslässt, gerät dein Ziel in Gefahr.|Noch $remaining diesen Monat ($completed/$target). Heute schützt deinen Fortschritt.|Dein Monatsziel ($completed/$target) ist noch möglich. Heute ist ein wichtiger Schritt.|$completed/$target in diesem Monat. Lass heute keine Lücke entstehen.|Noch $remaining diesen Monat ($completed/$target). Eine Session nach der anderen hält dich auf Kurs.|Monatsziel in Reichweite ($completed/$target). Heute hält die Tür offen.';
  }

  @override
  String notificationScheduleMonthlyImpossible(
    Object completed,
    Object target,
  ) {
    return 'Das Monatsziel wird diesmal nicht erreicht ($completed/$target). Nutze die restlichen Tage zum Üben, nicht für Druck.|Die Monatszahl ist außer Reichweite ($completed/$target). Aber Gewohnheiten entstehen in den Lücken, nicht nur bei den Zielen.|Ziel diesen Monat nicht erreichbar ($completed/$target). Jeder Versuch festigt trotzdem die Routine.|$completed/$target in diesem Monat. Das Ziel klappt nicht – aber die Gewohnheit zählt trotzdem.|Das Monatsziel war höher als deine verfügbaren Tage ($completed/$target). Pass es an und mach weiter.';
  }

  @override
  String notificationScheduleMonthlyOneLeft(Object completed, Object target) {
    return 'Noch eine Erledigung diesen Monat und du erreichst dein Ziel ($completed/$target).|Noch eine diesen Monat und du bist bei $target ($completed erledigt). Das ist dein letzter Schritt.|Du bist eine Session von deinem Monatsziel entfernt ($completed/$target). Mach es klar.|Dem Monatsziel fehlt nur noch eine Erledigung ($completed/$target). Heute kann der Tag sein.|Noch eine und du bist bei $target für diesen Monat ($completed erledigt). Bring zu Ende, was du angefangen hast.|Dein Monatsziel ist nur eine entfernt ($completed/$target). Das ist eine einzige Session.';
  }

  @override
  String notificationScheduleMonthlyReached(Object completed, Object target) {
    return 'Monatsziel schon erreicht ($completed/$target). Jede Extrarunde bringt extra Schwung.|Du hast dein Monatsziel geknackt ($completed/$target). Das ist Beständigkeit auf Top-Niveau.|Monatsziel: erledigt ($completed/$target). Alles ab jetzt ist Bonus-Wachstum.|Monatsziel schon übertroffen ($completed/$target). Bonusrunden festigen die Routine.';
  }

  @override
  String notificationScheduleMonthlyRemaining(Object remaining, Object target) {
    return 'Du brauchst diesen Monat noch $remaining, um $target zu erreichen.|Noch $remaining Sessions diesen Monat bis $target. Gleichmäßiges Tempo gewinnt.|Dir fehlen noch $remaining für dein Monatsziel von $target. Jede einzelne zählt.|Monatsziel: noch $remaining von $target. Du hast Zeit – nutze sie gut.|Noch $remaining diesen Monat bis $target. Kleine, stetige Schritte schließen die Lücke.|Deine Monatszahl ist $target, noch $remaining offen. Heute bringt dich dem Ziel näher.';
  }

  @override
  String notificationScheduleWeeklyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  ) {
    return 'Du brauchst diese Woche noch $remaining ($completed/$target erledigt). Wenn du heute auslässt, wird dein Ziel viel schwerer.|Du brauchst diese Woche noch $remaining ($completed/$target). Heute hält es machbar.|Noch $remaining diese Woche ($completed/$target). Heute auszulassen erhöht den Druck.|Dein Wochenziel ($completed/$target) ist noch erreichbar. Heute ist ein entscheidender Moment.|$completed/$target diese Woche. Eine heute hält dein Ziel auf Kurs.|Noch $remaining diese Woche ($completed/$target). Heute ist dein bester Zug.';
  }

  @override
  String notificationScheduleWeeklyImpossible(Object completed, Object target) {
    return 'Das Wochenziel ist außer Reichweite ($completed/$target). Trotzdem bereitet dich jede Runde auf nächste Woche vor.|Das Ziel wird diese Woche nicht erreicht ($completed/$target). Aber unvollendete Wochen zeigen uns, was wir anpassen sollten.|Die Wochenzahl klappt nicht ($completed/$target). Mach es trotzdem – Beständigkeit ignoriert die Anzeigetafel.|Ziel diese Woche verpasst ($completed/$target). Jeder Versuch stärkt trotzdem die Gewohnheit.|$completed/$target diese Woche. Das Ziel ist außer Reichweite – die Gewohnheit nicht.';
  }

  @override
  String notificationScheduleWeeklyOneLeft(Object completed, Object target) {
    return 'Noch eine Erledigung diese Woche und du erreichst dein Ziel ($completed/$target).|Noch eine diese Woche und du bist bei $target ($completed erledigt). Schließ den Kreis.|Du bist eine Session von deinem Wochenziel entfernt ($completed/$target). Mach sie zählen.|Dem Wochenziel fehlt nur noch eine ($completed/$target). Du kannst es jetzt abschließen.|Nur noch eine Erledigung trennt dich diese Woche von $target ($completed erledigt).|Wochenziel in Reichweite: noch eine ($completed/$target). Das ist nur heute.';
  }

  @override
  String notificationScheduleWeeklyReached(Object completed, Object target) {
    return 'Wochenziel schon erreicht ($completed/$target). Das ist Bonus-Beständigkeit.|Du hast dein Wochenziel erreicht ($completed/$target). Alles Weitere ist ein Gewinn.|Wochenziel: geschafft ($completed/$target). Bonusrunden bauen Top-Gewohnheiten.|$completed/$target diese Woche. Du bist über dich hinausgewachsen.|Wochenziel schon erfüllt ($completed/$target). Du bist auf einem höheren Level unterwegs.|Du hast dein Wochenziel geschafft ($completed/$target). Jetzt ist alles Bonus.';
  }

  @override
  String notificationScheduleWeeklyRemaining(Object remaining, Object target) {
    return 'Du brauchst diese Woche noch $remaining, um $target zu erreichen.|Noch $remaining bis zum Wochenziel von $target. Gleichmäßiges Tempo funktioniert.|Du brauchst diese Woche noch $remaining. Heute ist ein guter Zeitpunkt für eine.|Wochenziel: noch $remaining von $target. Verteil den Aufwand.|Noch $remaining Sessions bis $target diese Woche. Jede einzelne zählt.|Dein Wochenziel ist $target, noch $remaining offen. Ein Schritt nach dem anderen.';
  }

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notificationsAreDisabled => 'Benachrichtigungen sind deaktiviert';

  @override
  String get notificationsOffDialogDesc =>
      'Schalte Benachrichtigungen ein, um Erinnerungen für diese Gewohnheit zu erhalten.';

  @override
  String get turnOn => 'Einschalten';

  @override
  String get now => 'Jetzt';

  @override
  String get numberOfDaysInARowYouHaveCompletedAllYourHabits =>
      'Anzahl der Tage in Folge, an denen du alle deine Gewohnheiten erledigt hast.';

  @override
  String
  get onlyVisibleOnDailyPlanEnableColorfulModeInSettingsToShowOnCompletion =>
      'Nur im Tagesplan sichtbar. Aktiviere den Modus „Bunt“ in den Einstellungen, damit er beim Abschließen angezeigt wird.';

  @override
  String get optOut => 'Deaktivieren';

  @override
  String get optionalHabit => 'Optionale Gewohnheit';

  @override
  String get optionalHabits => 'Optionale Gewohnheiten';

  @override
  String get orToChangeLabel => 'oder die Mengeneinheit';

  @override
  String get passphrase => 'Passphrase';

  @override
  String get perfectDaysStreak => 'Perfekte-Tage-Streak';

  @override
  String get preparingBackupName => 'Name der Sicherung vorbereiten...';

  @override
  String get profile => 'Profil';

  @override
  String get reorderingCategoriesBasedOnTime =>
      'Neuordnung der Kategorien nach der Zeit';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get resetChanges => 'Änderungen zurücksetzen?';

  @override
  String get sat => 'Sa';

  @override
  String get satoshi => 'Satoshi';

  @override
  String get save => 'Speichern';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get schedulingAndAlerts => 'Zeitplan und Erinnerungen';

  @override
  String get schedulingFallbackToAll => 'Rückfall auf \'Alle\' einplanen';

  @override
  String get selectAColorPaletteForYourInterface =>
      'Wähle eine Farbpalette für deine Oberfläche';

  @override
  String get selectHabitColor => 'Farbe der Gewohnheit wählen';

  @override
  String get selectHabitTime => 'GEWOHNHEITSZEIT AUSWÄHLEN:';

  @override
  String get selectTime => 'Zeit auswählen';

  @override
  String get selectTimeInterval => 'Zeitintervall wählen';

  @override
  String get selected => 'Ausgewählt';

  @override
  String get setAmountLabel => 'Mengeneinheit festlegen';

  @override
  String get setDuration => 'Dauer festlegen';

  @override
  String get setNotificationTime => 'Benachrichtigungszeit einstellen';

  @override
  String get setPassphrase => 'Passphrase festlegen';

  @override
  String get setSchedule => 'Zeitplan festlegen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get signinFirstError => 'Erste Anmeldung Fehler';

  @override
  String get skip => 'Überspringen';

  @override
  String skippedHabitFoundHabitsskippedTotal(Object habitsSkipped) {
    return 'Übersprungene Gewohnheit gefunden, $habitsSkipped insgesamt';
  }

  @override
  String get skippingHabitNotAllowedHabitDayBeforeSkipped =>
      'Überspringen der Gewohnheit nicht erlaubt, Gewohnheit am Vortag übersprungen';

  @override
  String get startTime => 'Startzeit';

  @override
  String get stats => 'Statistiken';

  @override
  String get subscriptions => 'Abonnements';

  @override
  String get sun => 'So';

  @override
  String syncErrorErrormessage(Object errorMessage) {
    return 'Sync-Fehler: $errorMessage';
  }

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get syncing => 'Synchronisieren...';

  @override
  String syncingProgressmessage(Object progressMessage) {
    return 'Synchronisierung: $progressMessage';
  }

  @override
  String get tappedAmount => 'Eingetragene Menge';

  @override
  String get tappedDuration => 'Eingetragene Dauer';

  @override
  String get thisAmountLabelWillBeRemoved =>
      'Diese Mengeneinheit wird entfernt.';

  @override
  String get thisLabelCantBeDeleted =>
      'Diese Einheit kann nicht gelöscht werden';

  @override
  String get thisNotificationCantBeDeleted =>
      'Diese Benachrichtigung kann nicht gelöscht werden';

  @override
  String get thisNotificationTimeWillBeRemoved =>
      'Diese Benachrichtigungszeit wird entfernt.';

  @override
  String
  get thisPassphraseIsUsedForYourDataEncryptionSaveItSecurelyYouWillUseItAgainWhenGettingYourDataOnOtherDevices =>
      'Diese Passphrase wird zur Verschlüsselung deiner Daten verwendet. Bewahre sie sicher auf, du brauchst sie wieder, um deine Daten auf anderen Geräten abzurufen.';

  @override
  String get thisReminderWillTriggerOnlyOnScheduledHabitDays =>
      'Diese Erinnerung wird nur an geplanten Gewohnheitstagen ausgelöst.';

  @override
  String get thu => 'Do';

  @override
  String get time => 'Mal';

  @override
  String get times => 'Mal';

  @override
  String get step => 'Schritt';

  @override
  String get steps => 'Schritte';

  @override
  String get glass => 'Glas';

  @override
  String get glasses => 'Gläser';

  @override
  String get page => 'Seite';

  @override
  String get pages => 'Seiten';

  @override
  String get dl => 'dl';

  @override
  String get km => 'km';

  @override
  String get meal => 'Mahlzeit';

  @override
  String get meals => 'Mahlzeiten';

  @override
  String get to => 'Bis';

  @override
  String get toReceiveRemindersPleaseEnableNotificationPermissionsForHabitt =>
      'Um Erinnerungen zu erhalten, aktiviere bitte die Benachrichtigungen für Habitt.';

  @override
  String get toUseHabitRemindersEnableNotificationsInYourDeviceSettings =>
      'Um Erinnerungen zu nutzen, aktiviere Benachrichtigungen in den Einstellungen deines Geräts.';

  @override
  String get tue => 'Di';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get uploadingBackupToCloud => 'Backup in die Cloud hochladen!';

  @override
  String get useYourGoogleDriveToBackupEncryptedAppData =>
      'Nutze dein Google Drive, um verschlüsselte App-Daten zu sichern';

  @override
  String get wed => 'Mi';

  @override
  String get welcomeBack => 'Willkommen zurück';

  @override
  String get welcomeToHabitt => 'Willkommen bei Habitt.';

  @override
  String get whatAreYouCountingForThisHabit =>
      'Was zählst du bei dieser Gewohnheit?';

  @override
  String get whatShouldWeCallYou => 'Wie sollen wir dich nennen?';

  @override
  String get whatsUp => 'Was geht';

  @override
  String get wrapUp => 'Tagesabschluss';

  @override
  String get wrapUpReflectionHowDidYourHabitsGoToday =>
      'Tagesrückblick: Wie liefen deine Gewohnheiten heute?';

  @override
  String get youAreCurrentlyNotConnectedToYourGoogleAccount =>
      'Du bist derzeit nicht mit deinem Google-Konto verbunden.';

  @override
  String youCanPressNumberAbove(Object type) {
    return 'Du kannst auch auf die Zahl oben tippen, um $type zu ändern';
  }

  @override
  String get youHaveUnsavedChangesAreYouSureYouWantToGoBackAndDiscardThem =>
      'Du hast ungespeicherte Änderungen. Willst du wirklich zurückgehen und sie verwerfen?';

  @override
  String get youHaventAddedAnyHabitsYet =>
      'Du hast noch keine Gewohnheiten hinzugefügt';

  @override
  String get youWillUseThisPassphraseToDecryptYourDataWhenImportingIt =>
      'Du brauchst diese Passphrase, um deine Daten beim Import zu entschlüsseln.';

  @override
  String get yourName => 'Dein Name';

  @override
  String get gettingConsistantMakeNonOptional =>
      'Du bist bei dieser Gewohnheit richtig beständig. Überleg dir, sie nicht mehr optional zu machen, um dich etwas mehr zu fordern. Willst du diese Gewohnheit jetzt aktualisieren?';

  @override
  String get getPremium => 'Unterstütze das Projekt';

  @override
  String get enjoyAllBenefits => 'Genieße alle Vorteile der App';

  @override
  String get rateUs => 'Bewerte uns';

  @override
  String get reportBug => 'Einen Fehler melden';

  @override
  String get leaveFeedback => 'Feedback hinterlassen';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get privacyPolicy => 'Datenschutzbestimmungen';

  @override
  String get logOut => 'Abmelden';

  @override
  String get backupAndSync => 'Sicherung und Synchronisierung';

  @override
  String lastSynced(Object lastSynced) {
    return 'Zuletzt synchronisiert: $lastSynced';
  }

  @override
  String changeHabitTimesInPeriodWarning(Object period) {
    return 'Das Ändern der Anzahl der Tage, an denen die Gewohnheit in $period erscheint, löscht ausgewählte Tage';
  }

  @override
  String get habitDetails => 'Details zur Gewohnheit';

  @override
  String get deleteHabit => 'Gewohnheit löschen';

  @override
  String get markAsComplete => 'Als erledigt markieren';

  @override
  String get habitNotFound => 'Gewohnheit nicht gefunden';

  @override
  String get strength => 'Stärke';

  @override
  String get skipped => 'Übersprungen';

  @override
  String get streak => 'Streak';

  @override
  String get currentStreak => 'Aktueller Streak';

  @override
  String get longestStreak => 'Längster Streak';

  @override
  String get day => 'Tag';

  @override
  String get days => 'Tage';

  @override
  String get completionRate => 'Abschlussrate';

  @override
  String get completionRatio => 'Abschlussquote';

  @override
  String get last7Days => 'Letzte 7 Tage';

  @override
  String get consistency => 'Beständigkeit';

  @override
  String get yourActivityOverTime => 'Deine Aktivität im Zeitverlauf';

  @override
  String get less => 'Weniger';

  @override
  String get more => 'Mehr';

  @override
  String get allHabits => 'Alle Gewohnheiten';

  @override
  String get isScheduledToday => 'Heute geplant';

  @override
  String get time2 => 'Zeit';

  @override
  String get chooseIcon => 'Symbol auswählen';

  @override
  String get schedule => 'Zeitplan';

  @override
  String get habitType => 'Gewohnheitstyp';

  @override
  String get select => 'Auswählen';

  @override
  String get repeatEvery => 'Wiederholen alle:';

  @override
  String habitWillAppear(Object dayLabel, Object days) {
    return 'Diese Gewohnheit wird ab heute alle $days. $dayLabel erscheinen';
  }

  @override
  String get language => 'Sprache';

  @override
  String get chooseAppLanguage => 'Sprache der App wählen';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get mode => 'Modus';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get system => 'System';

  @override
  String get preferences => 'Einstellungen';

  @override
  String get allNotifications => 'Alle Benachrichtigungen';

  @override
  String get habitNotifications => 'Gewohnheits-Benachrichtigungen';

  @override
  String get notificationSettings => 'Einstellungen für Benachrichtigungen';

  @override
  String get dailyReminders => 'Tägliche Erinnerungen';

  @override
  String get next => 'Weiter';

  @override
  String get findALanguage => 'Sprache suchen';

  @override
  String get noLanguagesFound => 'Keine Sprachen gefunden';

  @override
  String get chooseLanguage => 'Sprache wählen';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get week => 'Woche';

  @override
  String get timesPerWeek => 'Mal pro Woche:';

  @override
  String get timesPerMonth => 'Mal pro Monat:';

  @override
  String get monthly => 'Monatlich';

  @override
  String get month => 'Monat';

  @override
  String habitWillAppearWeekly(Object amount, Object label) {
    return 'Diese Gewohnheit wird $amount $label pro Woche erscheinen, bis sie abgeschlossen ist';
  }

  @override
  String habitWillAppearMonthly(Object amount, Object label) {
    return 'Diese Gewohnheit wird $amount $label pro Monat erscheinen, bis sie abgeschlossen ist';
  }

  @override
  String get selectDaysForHabit => 'Wähle die Tage für diese Gewohnheit:';

  @override
  String leaveUnselected(Object period) {
    return 'Lass alles abgewählt, wenn die Gewohnheit an jedem Tag der/des $period erscheinen soll, bis die Ziele erreicht sind';
  }

  @override
  String get month2 => 'Monat';

  @override
  String get week2 => 'Woche';

  @override
  String get target => 'Ziel';

  @override
  String get name => 'Name';

  @override
  String get uploadPhoto => 'Foto hochladen';

  @override
  String get profileDetails => 'Profil-Details';

  @override
  String get email => 'E-Mail';

  @override
  String get youDontHaveAnEmailYet => 'Du hast noch keine E-Mail';

  @override
  String get yourUsername => 'Dein Nutzername';

  @override
  String get youreDoingGreat => 'Du machst das wirklich toll!';

  @override
  String get onboardingStep1Title =>
      'Gewohnheiten aufbauen, die wirklich halten';

  @override
  String get onboardingStep1Subtitle =>
      'Verfolge deinen Fortschritt. Bleib konsequent. Sieh dein Wachstum.';

  @override
  String get onboardingStep2Title => 'Gewohnheiten nach deinem Tempo';

  @override
  String get onboardingStep2Subtitle =>
      'Zähle Wiederholungen, messe Zeit oder markiere deine Gewohnheit einfach als erledigt.';

  @override
  String get onboardingStep3Title => 'Sieh deine echte Konstanz';

  @override
  String get onboardingStep3Subtitle =>
      'Streaks, Stärke, Wochenquote und Fortschritts-Insights an einem Ort.';

  @override
  String get onboardingStep4Title => 'Bleib auf Kurs';

  @override
  String get onboardingStep4Subtitle =>
      'Morgen-, Mittags- und Abenderinnerungen mit voller Kontrolle.';

  @override
  String get getStarted => 'Loslegen';

  @override
  String get onboardingDemoHabitStudying => 'Lernen';

  @override
  String get onboardingDemoHabitBrushTeeth => 'Zähne putzen';

  @override
  String get onboardingDemoHabitReadBook => 'Ein Buch lesen';

  @override
  String get onboardingDemoHabitPushUps => 'Liegestütze';

  @override
  String get supportDeveloper =>
      'Hilf mit, die App kostenlos zu halten und weiterzuentwickeln';

  @override
  String get autoBackup => 'Automatische Synchronisierung und Sicherung';

  @override
  String get backUpNow => 'Jetzt sichern';

  @override
  String get restoreFromBackup => 'Aus Sicherung wiederherstellen';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get keepHabitsSafe =>
      'Halte deine Gewohnheiten und Fortschritte sicher';

  @override
  String get neverBackedUp => 'Nie';

  @override
  String get migrateToSeamlessSync => 'Zu nahtloser Synchronisation migrieren';

  @override
  String get legacyBackupDescription =>
      'Deine Sicherung verwendet ein altes Passwort. Gib es einmal ein, um auf nahtlose, passwortfreie Synchronisation umzustellen.';

  @override
  String get migrate => 'Migrieren';

  @override
  String get enterOldPassphrase => 'Altes Passwort eingeben';

  @override
  String get syncFailed => 'Synchronisation fehlgeschlagen';

  @override
  String get disconnectGoogle => 'Google trennen';

  @override
  String get restoreWithDeltasTitle => 'Aktuelle Änderungen einschließen?';

  @override
  String get restoreWithDeltasDesc =>
      'Auf deinem Drive gibt es Änderungen, die nach diesem Backup gemacht wurden. Du kannst sie auf das wiederhergestellte Backup anwenden oder das Backup wie es ist wiederherstellen.';

  @override
  String get restoreWithDeltasInclude => 'Änderungen einschließen';

  @override
  String get restoreWithDeltasSkip => 'Nur wiederherstellen';

  @override
  String get restoreConfirmTitle => 'Aus Sicherung wiederherstellen?';

  @override
  String get restoreConfirmDesc =>
      'Deine Daten werden vollständig durch dieses Backup ersetzt. Alles, was du seit diesem Backup erfasst hast, geht verloren. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get restoreConfirmDescription =>
      'Dabei wird die Cloud-Sicherung mit deinen lokalen Daten zusammengeführt. Konflikte werden anhand der neuesten Änderungen aufgelöst.';

  @override
  String get restoreBackup => 'Wiederherstellen';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get backupHistory => 'Sicherungsverlauf';

  @override
  String get noBackupsFound => 'Keine Sicherungen gefunden';

  @override
  String backupDateToday(Object time) {
    return 'Heute um $time';
  }

  @override
  String backupDateYesterday(Object time) {
    return 'Gestern um $time';
  }

  @override
  String backupDateOther(Object month, Object day, Object time) {
    return '$day. $month um $time';
  }

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mär';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Okt';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dez';

  @override
  String get migrationFailed =>
      'Migration fehlgeschlagen. Überprüfe deine Passphrase.';

  @override
  String get pinProtection => 'PIN-Schutz';

  @override
  String get setPinTitle => 'PIN festlegen';

  @override
  String get setPinDesc =>
      'Erstelle eine Passphrase oder PIN (mindestens 4 Zeichen) als zusätzlichen Schutz für deinen Backup-Schlüssel.';

  @override
  String get setLocalPinDesc =>
      'Diese PIN wird zur Verschlüsselung deiner lokalen Backups verwendet. Ohne sie können deine Backup-Dateien nicht entschlüsselt werden.';

  @override
  String get disablePinTitle => 'PIN deaktivieren';

  @override
  String get disablePinDesc =>
      'Gib deine aktuelle PIN ein, um den PIN-Schutz zu entfernen.';

  @override
  String get unlockForSyncTitle => 'Backup entsperren';

  @override
  String get unlockForSyncDesc =>
      'Gib deine PIN ein, um das Backup für diese Sitzung zu entsperren.';

  @override
  String get pinHint => 'Passphrase oder PIN';

  @override
  String get pinTooShort => 'Muss mindestens 4 Zeichen haben';

  @override
  String get pinIncorrect => 'Falsche Passphrase oder PIN';

  @override
  String get unlockAction => 'Entsperren';

  @override
  String get disable => 'Deaktivieren';

  @override
  String get forgotPassphrase => 'Passphrase vergessen? Altes Backup verwerfen';

  @override
  String get discardOldBackupTitle => 'Altes Backup verwerfen?';

  @override
  String get discardOldBackupDesc =>
      'Dein altes verschlüsseltes Backup wird dauerhaft von Google Drive gelöscht und durch ein neues ersetzt. Deine lokalen Daten sind sicher.';

  @override
  String get discardOldBackupConfirm => 'Verwerfen';

  @override
  String get paywallUpgradeTo => 'Unterstütze das Projekt';

  @override
  String get paywallSupportUs =>
      'Hilf mit, Habitt kostenlos zu halten, indem du Unterstützer wirst oder eine einmalige Spende machst';

  @override
  String get paywallCustomScheduling => 'Individuelle Gewohnheitsplanung';

  @override
  String get paywallPerHabitNotifications =>
      'Benachrichtigungen pro Gewohnheit';

  @override
  String get paywallImprovementSuggestions =>
      'Verbesserungsvorschläge für Gewohnheiten';

  @override
  String get paywallCloudBackupSync => 'Cloud-Backup und Synchronisation';

  @override
  String get paywallBestValue => 'Bestes Angebot';

  @override
  String get paywallMostPopular => 'Am beliebtesten';

  @override
  String get paywallUpgradeNow => 'Jetzt unterstützen';

  @override
  String get paywallManageSubscription => 'Unterstützung verwalten';

  @override
  String get paywallCancel => 'Unterstützung beenden';

  @override
  String get paywallDowngrade => 'Unterstützung verringern';

  @override
  String get paywallUpgrade => 'Unterstützung erhöhen';

  @override
  String get currentPlan => 'Aktueller Plan';

  @override
  String renewsOn(String date) {
    return 'Verlängert am $date';
  }

  @override
  String get paywallYearly => 'Jährlicher Supporter';

  @override
  String get paywallMonthly => 'Monatlicher Supporter';

  @override
  String get paywallLifetime => 'Lebenslanger Supporter';

  @override
  String get paywallSixMonths => 'Halbjährlicher Supporter';

  @override
  String get paywallThreeMonths => 'Vierteljährlicher Supporter';

  @override
  String get paywallWeekly => 'Wöchentlicher Supporter';

  @override
  String get paywallPerYear => '/ Jahr';

  @override
  String get paywallPerMonth => '/ Monat';

  @override
  String get paywallPerSixMonths => '/ 6 Monate';

  @override
  String get paywallPerThreeMonths => '/ 3 Monate';

  @override
  String get paywallPerWeek => '/ Woche';

  @override
  String get paywallOneTimePurchase => 'Einmalige Zahlung';

  @override
  String get paywallProductsUnavailable =>
      'Pläne konnten nicht geladen werden. Bitte versuche es später erneut.';

  @override
  String get paywallRestorePurchases => 'Käufe wiederherstellen';

  @override
  String get premadeSectionWellnessSelfCare => 'Wellness / Selbstpflege';

  @override
  String get premadeSectionHealthFitness => 'Gesundheit & Fitness';

  @override
  String get premadeSectionProductivityGrowth => 'Produktivität & Wachstum';

  @override
  String get premadeHabitGoToBedEarly => 'Früh ins Bett';

  @override
  String get premadeHabitBrushTeeth => 'Zähne putzen';

  @override
  String get premadeHabitSkinCare => 'Hautpflege';

  @override
  String get premadeHabitWakeUpEarly => 'Früh aufstehen';

  @override
  String get premadeHabitShower => 'Duschen';

  @override
  String get premadeHabitRunning => 'Laufen';

  @override
  String get premadeHabitWalk => 'Spazieren gehen';

  @override
  String get premadeHabitGym => 'Fitnessstudio';

  @override
  String get premadeHabitNutrition => 'Ernährung';

  @override
  String get premadeHabitMedications => 'Medikamente';

  @override
  String get premadeHabitDrinkWater => 'Wasser trinken';

  @override
  String get premadeHabitStudying => 'Lernen';

  @override
  String get premadeHabitWork => 'Arbeit';

  @override
  String get premadeHabitResearch => 'Recherche';

  @override
  String get premadeHabitRead => 'Lesen';

  @override
  String get premadeHabitPraying => 'Beten';

  @override
  String get premadeHabitProductivitySession => 'Produktivitätssitzung';

  @override
  String get premadeSheetTitle => 'Gewohnheit auswählen';

  @override
  String get premadeSheetDescCreate =>
      'Wähle eine Gewohnheit aus Kategorien — oder überspringe und erstelle deine eigene';

  @override
  String get premadeSheetDescEdit =>
      'Benachrichtigungen, UI-Stil und Text werden basierend auf der gewählten Gewohnheit angepasst.';

  @override
  String get overrideCurrentConfigTitle =>
      'Aktuelle Konfiguration überschreiben?';

  @override
  String get overrideCurrentConfigDesc =>
      'Aktuelle Gewohnheitsdetails mit der Vorlage überschreiben oder aktuelle Optionen behalten?';

  @override
  String get overrideCurrentConfigOverride => 'Überschreiben';

  @override
  String get overrideCurrentConfigKeepCurrent => 'Aktuelle behalten';

  @override
  String get apply => 'Anwenden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get logOutDesc =>
      'Durch das Abmelden werden Backup und Synchronisierung deaktiviert, aber deine lokalen Daten bleiben auf diesem Gerät.';

  @override
  String get deleteAccountDesc =>
      'Löscht dein Konto von unseren Servern. Verschlüsselte Backups im habitt_backups-Ordner auf deinem Google Drive bleiben erhalten — lösche sie bei Bedarf manuell.';

  @override
  String get accountDeletedSuccessfully => 'Konto erfolgreich gelöscht';

  @override
  String accountDeletionFailed(Object errorMessage) {
    return 'Konto konnte nicht gelöscht werden: $errorMessage';
  }

  @override
  String get backupFound => 'Backup gefunden';

  @override
  String get backupFoundDesc =>
      'Dein Google Drive hat ein Backup. Wie möchtest du wiederherstellen?';

  @override
  String get merge => 'Zusammenführen';

  @override
  String get overwriteLocalDataTitle => 'Lokale Daten überschreiben?';

  @override
  String get overwriteLocalDataDesc =>
      'Dadurch werden alle deine lokalen Daten dauerhaft durch das Backup ersetzt. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get overwrite => 'Überschreiben';

  @override
  String get syncSectionTitle => 'Sync';

  @override
  String get syncSpeedTitle => 'Sync-Geschwindigkeit';

  @override
  String get syncSpeedFast => 'Schnell';

  @override
  String get syncSpeedOptimized => 'Optimiert';

  @override
  String get syncSpeedFastDescription =>
      'Nach 5 Sek. synchronisieren\nAlle 30 Sek. prüfen';

  @override
  String get syncSpeedFastHint =>
      'Änderungen werden nach 5 Sekunden hochgeladen und die Daten alle 30 Sekunden aktualisiert.';

  @override
  String get syncSpeedOptimizedDescription =>
      'Nach 15 Sek. synchronisieren\nAlle 2 Min. prüfen';

  @override
  String get syncSpeedOptimizedHint =>
      'Änderungen werden gebündelt und nach kurzer Pause hochgeladen, um den Akku zu schonen.';

  @override
  String get disconnectGoogleDrive => 'Google Drive trennen';

  @override
  String get connectGoogleDrive => 'Google Drive verbinden';

  @override
  String get pauseHabit => 'Gewohnheit pausieren';

  @override
  String pauseHabitName(Object name) {
    return '\'$name\' pausieren';
  }

  @override
  String get unpauseHabit => 'Pausierung aufheben';

  @override
  String get pauseHabitDesc =>
      'Während der Pause erscheint diese Gewohnheit nicht in deiner Tagesliste. Dein Streak und deine Statistiken bleiben erhalten.';

  @override
  String get habitPaused => 'Gewohnheit pausiert!';

  @override
  String get habitUnpaused => 'Gewohnheit fortgesetzt!';

  @override
  String get localBackups => 'Lokale Sicherungen';

  @override
  String get localBackupsDesc =>
      'Verschlüsselte Sicherungsdateien auf diesem Gerät exportieren oder importieren';

  @override
  String get exportBackup => 'Sicherung exportieren';

  @override
  String get exportBackupDesc =>
      'Eine verschlüsselte Sicherungsdatei auf dem Gerät speichern';

  @override
  String get importBackup => 'Sicherung importieren';

  @override
  String get importBackupDesc =>
      'Aus einer verschlüsselten Sicherungsdatei wiederherstellen';

  @override
  String get exportSuccess => 'Sicherung erfolgreich exportiert.';

  @override
  String get exportFailed => 'Export fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get importSuccess => 'Sicherung erfolgreich importiert.';

  @override
  String get importFailed => 'Import fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get setPin => 'PIN festlegen';

  @override
  String get pinEnabled => 'PIN aktiviert';

  @override
  String get changePin => 'PIN ändern';

  @override
  String get removePin => 'PIN entfernen';

  @override
  String get revealPin => 'PIN anzeigen';

  @override
  String get confirmPin => 'PIN bestätigen';

  @override
  String get currentPin => 'Aktueller PIN';

  @override
  String get newPin => 'Neuer PIN';

  @override
  String get confirmNewPin => 'Neuen PIN bestätigen';

  @override
  String get pinMismatch => 'PINs stimmen nicht überein';

  @override
  String get pinChangedSuccess => 'PIN geändert';

  @override
  String get pinRemovedSuccess => 'PIN entfernt';

  @override
  String get pinSetSuccess => 'PIN festgelegt';

  @override
  String get pinCopied => 'PIN kopiert';

  @override
  String get exportUnencryptedWarningTitle =>
      'Ohne Verschlüsselung exportieren?';

  @override
  String get exportUnencryptedWarningDesc =>
      'Kein PIN gesetzt. Diese Backup-Datei wird nicht verschlüsselt. Jeder mit Zugriff auf die Datei kann deine Daten lesen.';

  @override
  String get exportUnencryptedConfirm => 'Trotzdem exportieren';

  @override
  String get enterPinToDecrypt => 'Backup-PIN eingeben';

  @override
  String get wrongPin => 'Falscher PIN. Bitte erneut versuchen.';

  @override
  String get importSuccessPinSaved =>
      'Backup importiert. PIN für zukünftige Backups gespeichert.';

  @override
  String get useThisPinQuestion =>
      'Diesen PIN für zukünftige Backups verwenden?';

  @override
  String get savePin => 'PIN speichern';

  @override
  String get removePinDesc =>
      'Zukünftige Backup-Dateien werden nicht verschlüsselt. Jeder mit Zugriff auf die Datei kann deine Daten lesen.';

  @override
  String get connectICloud => 'iCloud verbinden';

  @override
  String get disconnectICloud => 'iCloud trennen';

  @override
  String get syncFailedDrive => 'Google Drive-Synchronisierung fehlgeschlagen';

  @override
  String get syncFailedICloud =>
      'iCloud nicht verfügbar — Einstellungen prüfen';

  @override
  String get syncFailedICloudQuota => 'Nicht genug iCloud-Speicherplatz';

  @override
  String get syncWarningICloudQuota =>
      'Apple-Speicher voll — Daten nur lokal gespeichert';

  @override
  String get syncFailedDriveQuota => 'Google Drive-Speicher voll';

  @override
  String get singular => 'Einzahl';

  @override
  String get singularHint => 'z. B. Glas';

  @override
  String get plural => 'Mehrzahl';

  @override
  String get pluralHint => 'z. B. Gläser';

  @override
  String get habitNames => 'Gewohnheitsnamen';

  @override
  String get habitNamesDesc =>
      'Lege für jede Sprache einen eigenen Gewohnheitsnamen fest. Wenn du die App-Sprache wechselst, wird automatisch der passende Name angezeigt.';

  @override
  String get autoAssignHabitNames => 'Gewohnheitsnamen automatisch zuweisen';

  @override
  String get autoAssignHabitNamesDesc =>
      'Speichert bei jedem Speichern automatisch den Gewohnheitsnamen für die aktuelle Sprache.';

  @override
  String get holdToCompleteTipTitle => 'Gedrückt halten zum Abschließen';

  @override
  String get holdToCompleteTipBody =>
      'Halte das Häkchen gedrückt, um dein Ziel sofort vollständig einzutragen.';

  @override
  String get syncOverlayTitleSyncing => 'Synchronisieren';

  @override
  String get syncOverlayTitleUploading => 'Hochladen';

  @override
  String get syncOverlayTitleUpToDate => 'Aktuell';

  @override
  String syncOverlayUpdatesRemaining(int count) {
    return 'Noch $count Aktualisierungen...';
  }

  @override
  String get syncOverlayDownloadingBackup => 'Backup wird heruntergeladen...';

  @override
  String get syncOverlayUploadingChanges =>
      'Letzte Änderungen werden hochgeladen...';

  @override
  String get showUploadActivity => 'Upload-Aktivität anzeigen';

  @override
  String get showUploadActivityDesc =>
      'Wenn aktiviert, wird beim Hochladen von Änderungen in die Cloud ein Synchronisierungsoverlay angezeigt. Deaktivieren für stilles Hochladen im Hintergrund.';

  @override
  String get syncOverlayTitleOptimizing => 'Optimierung';

  @override
  String syncOverlayOptimizingRemaining(int count) {
    return '$count Dateien verbleibend...';
  }

  @override
  String get followHabitSchedule => 'Gewohnheitsplan folgen';

  @override
  String get notificationScheduleDependencyTip =>
      'Diese Erinnerung erscheint nur an Tagen, an denen die Gewohnheit geplant ist.';

  @override
  String get notificationWeekdaysFixedTip =>
      'Die Gewohnheit erscheint nie an deaktivierten Tagen. Um dies zu ändern, bearbeite deine Planungsoptionen.';

  @override
  String get importHabitKitDesc =>
      'Deine Gewohnheiten und dein Verlauf werden importiert.';

  @override
  String importHabitKitMergeDesc(String appName) {
    return 'Behalte deine Gewohnheiten und füge die aus $appName hinzu. Gewohnheiten mit gleichem Namen werden zusammengeführt.';
  }

  @override
  String importHabitKitReplaceDesc(Object appName) {
    return 'Lösche zuerst deine aktuellen Gewohnheiten und importiere dann. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get importHabitKitNote =>
      'Symbole und Farben können sich ändern, „schlechte Gewohnheiten” werden als normale Gewohnheiten importiert';

  @override
  String get replace => 'Ersetzen';

  @override
  String get importFromOtherApps => 'Aus anderen Apps importieren';

  @override
  String importHabitKitTitle(String appName) {
    return '$appName-Daten importieren';
  }

  @override
  String get backupBeforeImporting =>
      'Es wird dringend empfohlen, deine Daten zu sichern, bevor du fortfährst.';

  @override
  String get streakCelebration => 'Serien-Feier';

  @override
  String get streakCelebrationDesc =>
      'Zeige eine Feier, wenn deine Serie perfekter Tage wächst.';

  @override
  String get completionSound => 'Abschluss-Sound';

  @override
  String get completionSoundDesc =>
      'Spiele einen kurzen Sound ab, wenn du eine Gewohnheit abschließt.';

  @override
  String get greatProgress => 'Toller Fortschritt';

  @override
  String get buildingRealConsistency => 'Du baust echte Beständigkeit auf';

  @override
  String get keepGoing => 'Weiter so!';

  @override
  String get goodJob => 'Gut gemacht!';

  @override
  String get bravo => 'Bravo!';

  @override
  String get keepItUp => 'Mach weiter so!';

  @override
  String get youreALegend => 'Du bist eine Legende!';

  @override
  String get streakInventYou =>
      'Wenn es dich nicht gäbe, müsste man dich erfinden!';

  @override
  String get streakPraiseExtra1 => 'So macht man das, Champ!';

  @override
  String get streakPraiseExtra2 => 'Gut gemacht, du!';

  @override
  String get streakPraiseExtra3 => 'Hut ab vor dir!';

  @override
  String get backAtIt => 'Wieder dabei';

  @override
  String get timeForHabits => 'Zeit für Gewohnheiten?';

  @override
  String get notificationCompleteAction => 'Erledigt';

  @override
  String get notificationSoundSettingTitle => 'Benachrichtigungston';

  @override
  String get notificationSoundSettingSubtitle => 'Ton für Erinnerungen';

  @override
  String get habitSoundTitle => 'Erinnerungston';

  @override
  String get useGlobalDefaultSound => 'Standard verwenden';

  @override
  String soundNumbered(int number) {
    return 'Ton $number';
  }

  @override
  String get notificationSoundAppDefault => 'App-Standard';

  @override
  String get notificationSoundSystemDefault => 'System-Standard';

  @override
  String get optional => 'Optional';

  @override
  String get becomeASupporter => 'Werde Unterstützer';

  @override
  String get or => 'oder';

  @override
  String get buyMeACoffee => 'Spendier mir einen Kaffee';

  @override
  String get makeOneTimeDonationOfAnyAmount =>
      'Mach eine einmalige Spende in beliebiger Höhe';

  @override
  String get donate => 'Spenden';

  @override
  String get everyDonationHelpsSupportFutureUpdates =>
      'Jede Spende hilft, zukünftige Updates zu unterstützen';

  @override
  String get today => 'Heute';

  @override
  String get showCategoriesOnMainPage => 'Gewohnheitskategorien';

  @override
  String get showCategoriesOnMainPageDesc =>
      'Über deinen Gewohnheiten auf der Startseite erscheint ein Kategoriefilter.';

  @override
  String get outdatedDeviceTitle => 'Aktualisiere dein anderes Gerät';

  @override
  String get outdatedDeviceMessage =>
      'Ein anderes Gerät in deinem Konto verwendet eine veraltete Version von Habitt. Bitte aktualisiere es auf die neueste Version, um eine ordnungsgemäße Synchronisierung zu gewährleisten.';

  @override
  String get gotIt => 'Verstanden';

  @override
  String get timerDialogTitle => 'Timer starten';

  @override
  String get timerCloseHint =>
      'Du kannst diesen Bildschirm schließen. Der Timer läuft weiter';

  @override
  String get timerInProgress => 'Läuft...';

  @override
  String get timerPaused => 'Pausiert';

  @override
  String get completeHabit => 'Gewohnheit abschließen';

  @override
  String get timerPauseToEditHint =>
      'Pausiere den Timer, um den Fortschritt manuell zu bearbeiten';

  @override
  String get timerAlreadyRunningTitle => 'Ein Timer läuft bereits';

  @override
  String timerSwitchDesc(String name) {
    return 'Aktuellen Timer stoppen und stattdessen einen für „$name“ starten?';
  }

  @override
  String get timerStopAndStart => 'Stoppen & starten';

  @override
  String get habitPausedDesc =>
      'Diese Gewohnheit ist derzeit pausiert. Um Fortschritt hinzuzufügen, musst du sie zuerst fortsetzen.';

  @override
  String get habitDeletedDesc =>
      'Diese Gewohnheit wurde gelöscht. Um Fortschritt hinzuzufügen, musst du sie zuerst wiederherstellen.';

  @override
  String get deleted => 'Gelöscht';

  @override
  String get noDeletedHabits => 'Keine gelöschten Gewohnheiten';

  @override
  String get deletedHabits => 'Gelöschte Gewohnheiten';

  @override
  String get unpause => 'Fortsetzen';

  @override
  String get habitRestored => 'Gewohnheit wiederhergestellt!';

  @override
  String get later => 'Später';

  @override
  String get consistencyMessage =>
      'Du hast in letzter Zeit nachgelassen. Gib nochmal richtig Gas!';

  @override
  String get current => 'Aktuell';

  @override
  String get suggested => 'Vorgeschlagen';

  @override
  String get needed => 'Benötigt';

  @override
  String get streakFadingNudge1 => 'Lass dich nicht hängen';

  @override
  String get streakFadingNudge2 => 'Dein Streak schwächelt';

  @override
  String get streakFadingNudge3 => 'Zeit, wieder einzusteigen';

  @override
  String get streakFadingPartial1 => 'Guter Anfang, jetzt zu Ende bringen';

  @override
  String get streakFadingPartial2 => 'Fast geschafft, mach es fertig';

  @override
  String get streakCriticalWarning1 =>
      'Letzte Chance, deinen Streak zu retten!';

  @override
  String get streakCriticalWarning2 => 'Verpass heute nicht!';

  @override
  String get streakCriticalPartial1 =>
      'Heute abschließen und deinen Streak verlängern';

  @override
  String get streakCriticalPartial2 => 'So nah dran, mach fertig und er wächst';

  @override
  String get deletedToday => 'Heute';

  @override
  String get deletedOneDayAgo => 'Vor 1 Tag';

  @override
  String deletedDaysAgoLabel(Object days) {
    return 'Vor $days Tagen';
  }

  @override
  String get deletedHabitsPageDesc =>
      'Gelöschte Gewohnheiten bleiben hier 30 Tage lang und werden dann endgültig entfernt.';

  @override
  String get restoreDeletedHabitConfirm =>
      'Diese Gewohnheit wiederherstellen? Ihr Streak berücksichtigt alle Tage, die sie im gelöschten Zustand verpasst hat.';

  @override
  String get healthSyncSectionTitleApple => 'Mit Apple Health synchronisieren';

  @override
  String get healthSyncSectionTitleAndroid =>
      'Mit Health Connect synchronisieren';

  @override
  String get healthSyncSectionDescApple =>
      'Fortschritt dieser Gewohnheit automatisch aus Apple Health aktualisieren';

  @override
  String get healthSyncSectionDescAndroid =>
      'Fortschritt dieser Gewohnheit automatisch aus Health Connect aktualisieren';

  @override
  String get healthMetricSteps => 'Schritte';

  @override
  String get healthMetricSleep => 'Schlaf';

  @override
  String get healthMetricExerciseMinutes => 'Training';

  @override
  String get healthMetricMindfulMinutes => 'Achtsamkeit';

  @override
  String get healthMetricActivity => 'Aktivität';

  @override
  String get healthMetricActiveCalories => 'Aktive Kalorien';

  @override
  String get healthMetricTotalCalories => 'Kalorien gesamt';

  @override
  String get healthPermissionDeniedMessage =>
      'Habitt hat keine Berechtigung, diese Daten zu lesen. Du kannst den Zugriff in den Einstellungen erlauben.';

  @override
  String get calorie => 'Kalorie';

  @override
  String get calories => 'Kalorien';

  @override
  String get premadeSectionWorkouts => 'Workouts';

  @override
  String get premadeHabitWorkoutWalking => 'Gehen';

  @override
  String get premadeHabitWorkoutRunning => 'Laufen';

  @override
  String get premadeHabitWorkoutCycling => 'Radfahren';

  @override
  String get premadeHabitWorkoutSwimming => 'Schwimmen';

  @override
  String get premadeHabitWorkoutHiking => 'Wandern';

  @override
  String get premadeHabitWorkoutFlexibility => 'Dehnen';

  @override
  String get premadeHabitWorkoutDancing => 'Tanzen';

  @override
  String get premadeHabitWorkoutRowing => 'Rudern';

  @override
  String get premadeHabitWorkoutCombined => 'Training';

  @override
  String get healthConnectedStatusApple => 'Mit Apple Health verbunden';

  @override
  String get healthConnectedStatusAndroid => 'Mit Health Connect verbunden';

  @override
  String get healthTrackByDuration => 'Dauer';

  @override
  String get healthTrackByCount => 'Anzahl';

  @override
  String get healthTargetBedtime => 'Ziel-Schlafenszeit';

  @override
  String get healthTargetWakeTime => 'Ziel-Aufwachzeit';

  @override
  String get healthToleranceLoose => 'Locker';

  @override
  String get healthToleranceRegular => 'Normal';

  @override
  String get healthToleranceStrict => 'Streng';

  @override
  String get healthLastNight => 'Letzte Nacht';

  @override
  String get healthMetricPickerTitle => 'Wähle, was synchronisiert wird';

  @override
  String get premadeRequestHabitPrompt => 'Deine Gewohnheit ist nicht dabei?';

  @override
  String get premadeRequestHabitLink => 'Vorschlagen';

  @override
  String get habitRequestEmailSubject => 'Gewohnheitsvorschlag';

  @override
  String healthToleranceMinutesValue(Object minutes) {
    return '$minutes Minuten';
  }

  @override
  String get healthToleranceHourValue => '1 Stunde';

  @override
  String healthToleranceDescBedtime(Object duration) {
    return 'Früher als dein Ziel ins Bett zu gehen ist immer in Ordnung. Du kannst auch bis zu $duration später gehen und es zählt trotzdem';
  }

  @override
  String healthToleranceDescWakeTime(Object duration) {
    return 'Früher als dein Ziel aufzuwachen ist immer in Ordnung. Du kannst auch bis zu $duration später aufwachen und es zählt trotzdem';
  }

  @override
  String healthToleranceDescSleep(Object duration) {
    return 'Länger als dein Ziel zu schlafen ist immer in Ordnung. Du kannst auch bis zu $duration weniger schlafen und es zählt trotzdem';
  }

  @override
  String get healthMetricDescSteps => 'Erfasst deine Schritte';

  @override
  String get healthMetricDescSleep => 'Erfasst deine Schlafdauer';

  @override
  String get healthMetricDescWorkouts => 'Erfasst alle deine Workouts';

  @override
  String get healthMetricDescMindfulness =>
      'Erfasst deine Achtsamkeitseinheiten';

  @override
  String get healthMetricDescActivity =>
      'Erfasst deinen Trainingsring von der Apple Watch';

  @override
  String get healthMetricDescActiveCalories =>
      'Erfasst deine verbrannten aktiven Kalorien';

  @override
  String get healthMetricDescTotalCalories =>
      'Erfasst deine insgesamt verbrannten Kalorien';

  @override
  String get healthMetricDescBedtime =>
      'Erfasst, wann du schlafen gegangen bist';

  @override
  String get healthMetricDescWakeTime => 'Erfasst, wann du aufgewacht bist';

  @override
  String get premadeHabitMindfulness => 'Achtsamkeit';

  @override
  String get premadeHabitActivity => 'Aktivität';

  @override
  String get premadeHabitSleepTime => 'Schlafdauer';

  @override
  String get premadeHabitActiveCalories => 'Aktive Kalorien';

  @override
  String get premadeHabitTotalCalories => 'Kalorien gesamt';

  @override
  String get healthWorkoutTypePickerTitle => 'Wähle eine Trainingsart';

  @override
  String get healthWorkoutFilterAny => 'Beliebig';

  @override
  String get healthWorkoutLabelAnySingular => 'Training';

  @override
  String get healthWorkoutLabelAnyPlural => 'Trainings';

  @override
  String get healthWorkoutLabelOtherSingular => 'Training';

  @override
  String get healthWorkoutLabelOtherPlural => 'Trainings';

  @override
  String get healthWorkoutLabelWalkingSingular => 'Spaziergang';

  @override
  String get healthWorkoutLabelWalkingPlural => 'Spaziergänge';

  @override
  String get healthWorkoutLabelRunningSingular => 'Lauf';

  @override
  String get healthWorkoutLabelRunningPlural => 'Läufe';

  @override
  String get healthWorkoutLabelCyclingSingular => 'Fahrt';

  @override
  String get healthWorkoutLabelCyclingPlural => 'Fahrten';

  @override
  String get healthWorkoutLabelSwimmingSingular => 'Schwimmeinheit';

  @override
  String get healthWorkoutLabelSwimmingPlural => 'Schwimmeinheiten';

  @override
  String get healthWorkoutLabelHikingSingular => 'Wanderung';

  @override
  String get healthWorkoutLabelHikingPlural => 'Wanderungen';

  @override
  String get healthWorkoutLabelFlexibilitySingular => 'Einheit';

  @override
  String get healthWorkoutLabelFlexibilityPlural => 'Einheiten';

  @override
  String get healthWorkoutLabelDancingSingular => 'Tanz';

  @override
  String get healthWorkoutLabelDancingPlural => 'Tänze';

  @override
  String get healthWorkoutLabelRowingSingular => 'Rudereinheit';

  @override
  String get healthWorkoutLabelRowingPlural => 'Rudereinheiten';

  @override
  String get healthMindfulnessLabelSingular => 'Einheit';

  @override
  String get healthMindfulnessLabelPlural => 'Einheiten';

  @override
  String get overrideFieldsDialogTitle => 'Wähle, was aktualisiert wird';

  @override
  String get overrideFieldsDialogDesc =>
      'Wähle aus, welche Teile deiner Gewohnheit an diese Vorlage angepasst werden sollen. Alles, was nicht angehakt ist, behält seinen aktuellen Wert.';

  @override
  String get overrideFieldsSelectAll => 'Alle auswählen';

  @override
  String get overrideFieldsDeselectAll => 'Alle abwählen';

  @override
  String get overrideFieldName => 'Name';

  @override
  String get overrideFieldIcon => 'Symbol';

  @override
  String get overrideFieldCategory => 'Kategorie';

  @override
  String get overrideFieldTarget => 'Ziel';

  @override
  String get overrideFieldHealthSync => 'Health-Synchronisierung';

  @override
  String get overrideFieldSchedule => 'Zeitplan';

  @override
  String get overrideFieldNotifications => 'Benachrichtigungen';

  @override
  String get timerCompletedNotificationTitle => 'Ziel erreicht';

  @override
  String timerCompletedNotificationBody(String name) {
    return '\'$name\' hat das Ziel erreicht.';
  }

  @override
  String get healthBedtimeDayTitle => 'Schlafenszeit zählen für';

  @override
  String get healthBedtimeDayWake => 'Aufwachtag';

  @override
  String get healthBedtimeDayBefore => 'Vortag';

  @override
  String get healthBedtimeDayWakeDesc =>
      'Deine Schlafenszeit zählt für den Tag, an dem du aufwachst. Gehst du Montagabend ins Bett, zählt es für Dienstag';

  @override
  String get healthBedtimeDayBeforeDesc =>
      'Deine Schlafenszeit zählt für den Tag vor dem Aufwachen. Gehst du Montagabend ins Bett, zählt es für Montag';

  @override
  String get healthCardNotSyncedYet => 'Noch nicht synchronisiert';

  @override
  String get healthCardSyncing => 'Synchronisiere…';

  @override
  String get healthCardPermissionNeeded =>
      'Zugriff erlauben, um weiter zu synchronisieren';

  @override
  String get healthCardLast7Days => 'Letzte 7 Tage';

  @override
  String get healthCardNoData =>
      'Für diese Tage gibt es noch keine Health-Daten';

  @override
  String get healthCardSessions => 'Einheiten';

  @override
  String get healthCardNoSessions =>
      'Für diesen Tag wurden keine Einheiten aufgezeichnet';

  @override
  String notificationSleepHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String notificationSleepMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '1 Minute',
    );
    return '$_temp0';
  }

  @override
  String notificationSleepHoursAndMinutes(Object hours, Object minutes) {
    return '$hours und $minutes';
  }

  @override
  String notificationSleepBedtimeSoon(Object countdown, Object time) {
    return 'Mach dich bettfertig, deine Schlafenszeit ist in $countdown.|Zeit zum Runterkommen, deine Schlafenszeit ist in $countdown.|Starte deine Abendroutine, in $countdown geht das Licht aus.|Fast Schlafenszeit! Noch $countdown bis $time.';
  }

  @override
  String notificationSleepBedtime(Object time) {
    return 'Nur eine Erinnerung, heute früh schlafen zu gehen.|Dein Schlafenszeit-Ziel ist $time. Fang an, runterzufahren.|Eine frühe Nacht macht den morgigen Tag leichter.|Leg bald dein Handy weg, deine Schlafenszeit ist $time.';
  }

  @override
  String notificationSleepWakeUp(Object time) {
    return 'Guten Morgen! Dein Aufsteh-Ziel ist $time.|Zeit aufzustehen, dein Ziel ist $time. Du schaffst das!|Aufstehen und strahlen, ein ruhiger früher Start lohnt sich.|Nur eine Erinnerung, früh aufzuwachen: dein Ziel ist $time.';
  }

  @override
  String notificationSleepGoal(Object goal) {
    return 'Peile heute Nacht $goal Schlaf an.|Geh rechtzeitig ins Bett, um heute Nacht volle $goal Schlaf zu bekommen.|Dein Ziel heute Nacht sind $goal Schlaf. Fang an, runterzufahren.|Schütze deinen Schlaf heute Nacht, das Ziel sind $goal.';
  }

  @override
  String notificationSleepGoalProgress(Object goal, Object slept) {
    return 'Du hast $slept von deinem Ziel von $goal geschlafen. Geh heute Nacht früher ins Bett.|Du liegst bei $slept von $goal Schlaf. Lass die heutige Nacht zählen.';
  }

  @override
  String notificationHealthStepsStart(Object goal) {
    return 'Zeit, in Bewegung zu kommen, dein Ziel heute sind $goal.|Ein Spaziergang bringt dich näher an $goal.|Jeder Schritt zählt, peile heute $goal an.|Streck die Beine, $goal warten auf dich.';
  }

  @override
  String notificationHealthStepsProgress(Object progress, Object remaining) {
    return 'Du bist bei $progress. Nur noch $remaining!|Noch $remaining bis zu deinem Ziel, lauf weiter.|Guter Fortschritt, bisher $progress. Ein kurzer Spaziergang schafft den Rest.';
  }

  @override
  String notificationHealthActiveCaloriesStart(Object goal) {
    return 'Bring deinen Körper in Bewegung, das Tagesziel sind $goal verbrannt.|Ein Workout oder zügiges Gehen bringt dich auf $goal.|Zeit, Energie zu verbrennen, dein Ziel sind $goal.|Beweg dich jetzt ein wenig, das Ziel heute sind $goal.';
  }

  @override
  String notificationHealthActiveCaloriesProgress(
    Object progress,
    Object remaining,
  ) {
    return 'Du hast bisher $progress verbrannt. Nur noch $remaining!|Noch $remaining bis zum Ziel, bleib in Bewegung.|Starke Leistung, $progress verbrannt. Zieh es durch!';
  }

  @override
  String notificationHealthTotalCaloriesStart(Object goal) {
    return 'Dein Gesamt-Kalorienziel für heute ist $goal. Bleib in Bewegung!|Beweg dich heute, das Gesamtziel sind $goal.|Dein Tagesziel für den Gesamtverbrauch: $goal. Etwas Bewegung hilft.';
  }

  @override
  String notificationHealthTotalCaloriesProgress(
    Object progress,
    Object remaining,
  ) {
    return 'Du bist heute bei $progress, noch $remaining bis zum Ziel.|Noch $remaining bis zum heutigen Kalorienziel.|Gutes Tempo, bisher $progress. Weiter so!';
  }

  @override
  String notificationHealthMindfulnessStart(Object goal) {
    return 'Nimm dir $goal zum Durchatmen und Zurücksetzen.|Eine kurze Achtsamkeitspause von $goal ist alles, was du brauchst.|Halte heute $goal für Achtsamkeit inne.|Dein Geist verdient $goal Ruhe.';
  }

  @override
  String notificationHealthMindfulnessProgress(
    Object progress,
    Object remaining,
  ) {
    return 'Bisher $progress Achtsamkeit. Noch $remaining bis zum Ziel.|Noch $remaining Ruhe bis zu deinem Ziel.';
  }

  @override
  String notificationHealthActivityStart(Object goal) {
    return 'Bewege dich heute $goal. Ein zügiger Spaziergang zählt.|Peile heute $goal Aktivität an, jede Bewegung zählt.|Zeit für Bewegung, dein Aktivitätsziel sind $goal.|Bleib in Bewegung, dein Ziel heute: $goal Aktivität.';
  }

  @override
  String notificationHealthActivityProgress(Object progress, Object remaining) {
    return 'Bisher $progress Aktivität. Noch $remaining bis zum Ziel.|Noch $remaining Aktivität, bleib in Bewegung!|Stark, heute schon $progress Aktivität. Nur noch $remaining.';
  }

  @override
  String notificationHealthWorkoutStart(Object activity, Object goal) {
    return '$activity: Dein Ziel heute ist $goal.|$activity steht heute auf dem Plan, peile $goal an.|$activity – Tagesziel: $goal. Los geht\'s!|$activity, los geht\'s! Das Ziel sind $goal.';
  }

  @override
  String notificationHealthWorkoutProgress(
    Object activity,
    Object progress,
    Object remaining,
  ) {
    return '$activity: bisher $progress, noch $remaining!|Fortschritt bei $activity: $progress. Weiter so, noch $remaining.|$activity: nur noch $remaining bis zum Ziel.';
  }

  @override
  String get notificationHealthNudgeWalking =>
      'Zeit für einen Spaziergang.|Frische Luft und ein Spaziergang tun dir gut.';

  @override
  String get notificationHealthNudgeRunning =>
      'Schnür die Schuhe, Zeit für eine Laufrunde.|Zeit, loszulaufen.';

  @override
  String get notificationHealthNudgeCycling =>
      'Schnapp dir dein Rad, Zeit für eine Fahrt.|Zeit für eine Radtour.';

  @override
  String get notificationHealthNudgeSwimming =>
      'Zeit fürs Schwimmbad.|Schnapp dir die Badesachen, Schwimmen wartet.';

  @override
  String get notificationHealthNudgeHiking =>
      'Die Wege rufen, Zeit für eine Wanderung.|Zeit, sich auf den Weg zu machen.';

  @override
  String get notificationHealthNudgeFlexibility =>
      'Nimm dir einen Moment zum Dehnen.|Zeit, dich zu dehnen.';

  @override
  String get notificationHealthNudgeDancing =>
      'Mach Musik an und tanz.|Zeit, sich zur Musik zu bewegen.';

  @override
  String get notificationHealthNudgeRowing =>
      'Zeit zum Rudern.|Schnapp dir die Ruder, eine Rudereinheit wartet.';

  @override
  String get healthEditedManually => 'Manuell bearbeitet';

  @override
  String healthUseSourceValues(Object source) {
    return '$source-Werte verwenden';
  }

  @override
  String healthOverrideNoticeTitle(Object source) {
    return '$source ist für diesen Tag pausiert';
  }

  @override
  String healthOverrideNoticeBody(Object source) {
    return 'Du hast den Fortschritt selbst geändert, deshalb überschreibt Habitt ihn für diesen Tag nicht mit Daten aus $source. Dein Wert bleibt genau so, wie du ihn eingegeben hast.\n\nMöchtest du $source zurück? Tippe bei dieser Gewohnheit auf \"$source-Werte verwenden\".';
  }

  @override
  String get healthOverrideNoticeUnderstood => 'Verstanden';

  @override
  String get separateOptionalHabits => 'Optionale Gewohnheiten trennen';

  @override
  String get separateOptionalHabitsDesc =>
      'Optionale Gewohnheiten wandern aus ihren Kategorien in einen eigenen Bereich am Ende, den du einklappen kannst.';

  @override
  String get strengthOverTime => 'Stärke im Zeitverlauf';

  @override
  String get strengthChartNotEnoughData =>
      'Weiter so. Dein Stärkeverlauf erscheint nach ein paar Tagen.';

  @override
  String get habitAgeStartedToday => 'Heute gestartet, viel Erfolg!';

  @override
  String get statsRange7Days => '7T';

  @override
  String get statsRange30Days => '30T';

  @override
  String get statsRangeAll => 'ALLE';

  @override
  String get noHabitsScheduledToday =>
      'Für heute sind keine Gewohnheiten geplant';

  @override
  String get noHabitsScheduledDay =>
      'Für diesen Tag sind keine Gewohnheiten geplant';

  @override
  String get noTimedHabitsToday =>
      'Keine der heutigen Gewohnheiten hat ein Zeitintervall';

  @override
  String get noTimedHabitsDay =>
      'Keine Gewohnheit an diesem Tag hat ein Zeitintervall';

  @override
  String get habitAgeCardTitle => 'Du machst das seit';

  @override
  String get habitAgeCardNew => 'Heute gestartet';

  @override
  String habitAgeCardYearsMonthsDays(Object years, Object months, Object days) {
    return '${years}J ${months}M ${days}T';
  }

  @override
  String get habitAgeMilestoneStarting => 'Du fängst gerade erst an';

  @override
  String get habitAgeMilestoneRhythm => 'Du findest deinen Rhythmus';

  @override
  String get habitAgeMilestoneRoutine => 'Das wird zur Routine';

  @override
  String get habitAgeMilestoneImpressive => 'Beeindruckend!';

  @override
  String get habitAgeMilestoneOutstanding => 'Hervorragend!';

  @override
  String get habitAgeMilestoneDedication => 'Ein ganzes Jahr. Das ist Hingabe!';

  @override
  String get habitAgeMilestoneLegendary => 'Legendäre Beständigkeit!';

  @override
  String get back => 'Zurück';

  @override
  String get setDaySchedule => 'Tagesplan festlegen';

  @override
  String get daySchedule => 'Tagesplan';

  @override
  String get daySchedulePrompt =>
      'Lege fest, wann diese Gewohnheit im Laufe des Tages stattfinden soll';

  @override
  String get noFixedTime => 'Keine feste Uhrzeit';

  @override
  String habitAppearsInSection(String section) {
    return 'Die Gewohnheit erscheint im Bereich $section';
  }

  @override
  String get specificTime => 'Bestimmte Uhrzeit';

  @override
  String get specificTimeDesc => 'Zu einer genauen Uhrzeit planen';

  @override
  String get timeRange => 'Zeitraum';

  @override
  String get timeRangeDesc => 'Mit Start- und Endzeit planen';

  @override
  String get setStartTime => 'Startzeit festlegen';

  @override
  String get setEndTime => 'Endzeit festlegen';

  @override
  String get setTimeRange => 'Zeitraum festlegen';

  @override
  String get startTimeLabel => 'Startzeit:';

  @override
  String get endTimeLabel => 'Endzeit:';

  @override
  String get startsAt => 'Beginnt um:';

  @override
  String get endsAt => 'Endet um:';

  @override
  String get timeRangeSameTimes =>
      'Start- und Endzeit dürfen nicht gleich sein';

  @override
  String get supportBannerText =>
      'Habitt hat keine Werbung, kein Tracking und kein Konto. Es besteht nur weiter, wenn Menschen, die es mögen, etwas beitragen.';

  @override
  String get supportSeeWays => 'Möglichkeiten zur Unterstützung ansehen';

  @override
  String get supportAlreadyDonated => 'Ich habe schon gespendet';

  @override
  String get supportBannerDismiss => 'Schließen';

  @override
  String get supporterThankYouTitle => 'Danke, dass du Habitt unterstützt';

  @override
  String get supporterThankYouDesc =>
      'Du hilfst, es für alle frei von Werbung und Tracking zu halten.';

  @override
  String get supportMilestoneText =>
      'Habitt hat keine Werbung und kein Tracking. Wenn es dir hilft, kannst du helfen, dass es weitergeht.';

  @override
  String get themeSettingTitle => 'Farbthema';

  @override
  String get themeNameHabitt => 'Habitt';

  @override
  String get themeNameLagoon => 'Lagune';

  @override
  String get themeNameOcean => 'Ozean';

  @override
  String get themeNameIndigo => 'Indigo';

  @override
  String get themeNameViolet => 'Violett';

  @override
  String get themeNameOrchid => 'Orchidee';

  @override
  String get supportSheetTitle => 'Kostenlos für alle';

  @override
  String get supportSheetDesc =>
      'Farbthemen und Cloud-Sicherung sind für alle kostenlos. Unterstützer halten Habitt am Laufen.';

  @override
  String get supportNotNow => 'Nicht jetzt';

  @override
  String get supportHabittRow => 'Unterstütze Habitt';
}
