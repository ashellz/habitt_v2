// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get accentColor => 'Couleur d\'accent';

  @override
  String get add => 'Ajouter';

  @override
  String get addANewAmountLabelYouCanReuseLater =>
      'Ajoute une nouvelle étiquette de quantité que tu pourras réutiliser plus tard.';

  @override
  String get addANotification => 'Ajouter une notification';

  @override
  String get addHabit => 'Ajouter une habitude';

  @override
  String get addMoreOptions => 'Ajouter plus d\'options';

  @override
  String get afternoon => 'Après-midi';

  @override
  String get all => 'Tout';

  @override
  String get allChangesYouMadeWillBeDiscarded =>
      'Toutes les modifications effectuées seront annulées.';

  @override
  String get allChangesYouveMadeNowWillBeReset =>
      'Toutes les modifications que tu as faites seront réinitialisées.';

  @override
  String get habitConfigDiscardDesc =>
      'Toute la configuration de l\'habitude sera annulée.';

  @override
  String get amount => 'Quantité';

  @override
  String get amountName => 'Nom de la quantité';

  @override
  String get anyTime => 'N\'importe quand';

  @override
  String get deleteHabitDesc =>
      'Es-tu sûr de vouloir supprimer cette habitude ?';

  @override
  String get optOutOfBackup => 'Désactiver la sauvegarde ?';

  @override
  String get backupData => 'Données de sauvegarde';

  @override
  String get backupDataDownloadedFromCloud =>
      'Données de sauvegarde téléchargées depuis le cloud.';

  @override
  String get backupDataFailedToDownloadFromCloud =>
      'Échec du téléchargement des données de sauvegarde depuis le cloud.';

  @override
  String get backupPassphrase => 'Phrase de passe de sauvegarde';

  @override
  String get calendar => 'Calendrier';

  @override
  String get cancel => 'Annuler';

  @override
  String get changeAColorThemeForYourInterface =>
      'Change le thème de couleurs de ton interface';

  @override
  String get changesSaved => 'Modifications enregistrées !';

  @override
  String get chooseHowColorfulTheUiShouldBe =>
      'Choisis le niveau de couleurs de l\'interface';

  @override
  String get clear => 'Effacer';

  @override
  String get clearSelectedDays => 'Effacer les jours sélectionnés';

  @override
  String get colorfulInterface => 'Interface colorée';

  @override
  String get complete => 'Terminé';

  @override
  String get completed => 'Terminée';

  @override
  String completedHabitFoundHabitscompletedTotal(Object habitsCompleted) {
    return 'Habitude terminée trouvée, $habitsCompleted au total';
  }

  @override
  String get completedHabits => 'Habitudes terminées : ';

  @override
  String get confirm => 'Confirmer';

  @override
  String get confirmDeletion => 'Confirmer la suppression';

  @override
  String get connectToGoogle => 'Se connecter à Google';

  @override
  String get controlWhenAndHowYouGetNotifiedAboutYourHabits =>
      'Contrôle quand et comment tu es notifié à propos de tes habitudes.';

  @override
  String get createAmountLabel => 'Créer une étiquette de quantité';

  @override
  String get custom => 'Personnalisé';

  @override
  String get daily => 'Quotidien';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get dateJoinedIsNull => 'La date d\'inscription est nulle';

  @override
  String get datejoined => 'date d\'inscription';

  @override
  String get dayEntryIsNull => 'L\'entrée du jour est nulle';

  @override
  String get decrementingHabitAmount =>
      'Diminution de la quantité de l\'habitude';

  @override
  String get defaultlabel => ', defaultLabel : ';

  @override
  String get delete => 'Supprimer';

  @override
  String deleteLabel(Object label) {
    return 'Supprimer « $label » ?';
  }

  @override
  String get deleteNotification => 'Supprimer la notification ?';

  @override
  String get discard => 'Abandonner';

  @override
  String get discardChanges => 'Abandonner les modifications ?';

  @override
  String get done => 'Terminé';

  @override
  String get driveApiReturnedNullFilesList =>
      'L\'API Drive a renvoyé une liste de fichiers vide';

  @override
  String get duration => 'Durée';

  @override
  String get edit => 'Modifier';

  @override
  String get editHabit => 'Modifier l\'habitude';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get enable => 'Activer';

  @override
  String get endTime => 'Heure de fin';

  @override
  String enterHabitNameToConfirmDeletion(Object habitName) {
    return 'Saisis « $habitName » pour confirmer la suppression';
  }

  @override
  String get enterPassphrase => 'Saisir la phrase de passe';

  @override
  String get enterYourAmount => 'Saisis ta quantité';

  @override
  String get enterYourDuration => 'Saisis ta durée';

  @override
  String get enterYourExistingBackupPassphraseToAccessYourData =>
      'Saisis ta phrase de passe de sauvegarde existante pour accéder à tes données.';

  @override
  String get evening => 'Soir';

  @override
  String get exit => 'Quitter';

  @override
  String get exitWithoutSaving => 'Quitter sans enregistrer ?';

  @override
  String get fetchOffers => 'Récupérer les offres';

  @override
  String get fri => 'Ven';

  @override
  String get from => 'De';

  @override
  String get getRemindedAboutYourHabit => 'Reçois un rappel pour ton habitude';

  @override
  String get glassFeel => 'Effet verre';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get morning => 'Matin';

  @override
  String get goodMorningTimeToCheckYourHabits =>
      'Bonjour ! C\'est le moment de vérifier tes habitudes';

  @override
  String get goodToSeeYou => 'Ravi de te voir';

  @override
  String get guest => 'Invité';

  @override
  String get habit => 'habitude';

  @override
  String get habitAdded => 'Habitude ajoutée !';

  @override
  String get habitDeleted => 'Habitude supprimée !';

  @override
  String get habitIsNotInABoxSkippingSave =>
      'L\'habitude n\'est pas dans une box, save() ignoré';

  @override
  String get habitName => 'Nom de l\'habitude';

  @override
  String get habitNotFoundInDayEntry =>
      'Habitude introuvable dans l\'entrée du jour';

  @override
  String get habits => 'habitudes';

  @override
  String get hello => 'Bonjour';

  @override
  String get helloThere => 'Salut toi';

  @override
  String get hi => 'Salut';

  @override
  String get hiThere => 'Hé, ça va ?';

  @override
  String get home => 'Accueil';

  @override
  String get hours => 'Heures';

  @override
  String get howAreYou => 'Comment tu vas';

  @override
  String get howLongWillThisHabitTake =>
      'Combien de temps va prendre cette habitude ?';

  @override
  String get howMuchDidYouCompleteToday =>
      'Combien as-tu accompli aujourd\'hui ?';

  @override
  String get howMuchTimeDidYouSpendOnThisHabitToday =>
      'Combien de temps as-tu consacré à cette habitude aujourd\'hui ?';

  @override
  String get howOftenWouldYouLikeToDoThisHabit =>
      'À quelle fréquence veux-tu faire cette habitude ?';

  @override
  String get ifCheckedHabitWontCountForThePerfectDaysStreak =>
      'Si coché, l\'habitude ne comptera pas dans la série de « jours parfaits ».';

  @override
  String get incorrectPassphrase => 'Phrase de passe incorrecte.';

  @override
  String get initialProgressValuesLoadedForAllDays =>
      'Valeurs de progression initiales chargées pour tous les jours';

  @override
  String get insightStrengthApplyDecrease => 'Appliquer la baisse';

  @override
  String get insightStrengthApplyIncrease => 'Appliquer la hausse';

  @override
  String insightStrengthIncreaseBrushTeeth(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien le brossage des dents. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec le brossage des dents. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Le brossage des dents est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec le brossage des dents. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur le brossage des dents. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseDrinkWater(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien l\'hydratation quotidienne. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec l\'hydratation quotidienne. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|L\'hydratation quotidienne est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec l\'hydratation quotidienne. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur l\'hydratation quotidienne. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseGeneric(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité est solide. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Tu gères bien cette habitude. La force est stable à $strength%. Passe de $fromValue à $toValue pour progresser encore.|L\'élan est solide ici. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu as construit une base fiable. La force est stable à $strength%. Passe de $fromValue à $toValue et continue à progresser.|Très belle régularité ces derniers temps. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour faire monter ta progression.';
  }

  @override
  String insightStrengthIncreaseGoToBedEarly(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien le coucher tôt. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec le coucher tôt. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Se coucher tôt est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec le coucher tôt. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur le coucher tôt. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseGym(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien ta routine en salle. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec ta routine en salle. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Ta routine en salle est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec ta routine en salle. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur ta routine en salle. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseNutrition(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien ton plan alimentaire. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec ton plan alimentaire. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Ton plan alimentaire est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec ton plan alimentaire. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur ton plan alimentaire. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreasePraying(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien la prière régulière. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec la prière régulière. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|La prière régulière est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec la prière régulière. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur la prière régulière. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseProductivitySession(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien tes sessions de productivité. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec tes sessions de productivité. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Tes sessions de productivité sont sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec tes sessions de productivité. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur tes sessions de productivité. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseRead(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien ton habitude de lecture. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec ton habitude de lecture. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Ton habitude de lecture est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec ton habitude de lecture. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur ton habitude de lecture. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseResearch(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien ton habitude de recherche. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec ton habitude de recherche. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Ton habitude de recherche est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec ton habitude de recherche. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur ton habitude de recherche. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseRunning(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien ta routine de course. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec ta routine de course. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Ta routine de course est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec ta routine de course. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur ta routine de course. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseShower(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien ta douche quotidienne. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec ta douche quotidienne. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Ta douche quotidienne est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec ta douche quotidienne. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur ta douche quotidienne. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseSkinCare(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien ta routine soin de la peau. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec ta routine soin de la peau. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Ta routine soin de la peau est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec ta routine soin de la peau. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur ta routine soin de la peau. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseStudying(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien ton habitude d\'étude. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec ton habitude d\'étude. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Ton habitude d\'étude est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec ton habitude d\'étude. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur ton habitude d\'étude. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseTargetTitle(Object habitName) {
    return 'Augmente ton objectif pour $habitName';
  }

  @override
  String insightStrengthIncreaseWakeUpEarly(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien le lever tôt. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec le lever tôt. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Le lever tôt est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec le lever tôt. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur le lever tôt. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseWalk(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien ta routine de marche. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec ta routine de marche. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Ta routine de marche est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec ta routine de marche. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur ta routine de marche. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthIncreaseWork(
    Object strength,
    Object fromValue,
    Object toValue,
  ) {
    return 'Tu gères très bien ton habitude de travail. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour continuer à progresser.|Très belle régularité avec ton habitude de travail. La force est stable à $strength%. Augmente ton objectif de $fromValue à $toValue et garde un bon élan.|Ton habitude de travail est sur une belle lancée. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour passer au niveau supérieur.|Tu tiens le rythme avec ton habitude de travail. La force est stable à $strength%. Passe de $fromValue à $toValue pour continuer à t\'améliorer.|Excellent rythme sur ton habitude de travail. La force est stable à $strength%. Objectif recommandé : $fromValue -> $toValue pour poursuivre tes progrès.';
  }

  @override
  String insightStrengthKeepPushingTitle(Object habitName) {
    return 'Continue à t\'investir dans « $habitName »';
  }

  @override
  String insightStrengthLowerTargetTitle(Object habitName) {
    return 'Ton objectif pour « $habitName » est peut-être trop élevé';
  }

  @override
  String get insightStrengthStartSmallType1BrushTeeth =>
      'Ton habitude de brossage des dents faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme avec le brossage des dents. Brosse-toi les dents aujourd\'hui et protège l\'habitude.|L\'élan autour du brossage des dents s\'essouffle. Garde-le vivant en te brossant les dents aujourd\'hui.|Ne laisse pas le brossage des dents devenir irrégulier. Concentre-toi et brosse-toi les dents aujourd\'hui.|Tu voulais commencer le brossage des dents pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1DrinkWater =>
      'Ton habitude de bien t\'hydrater faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme avec l\'hydratation quotidienne. Bois un verre d\'eau aujourd\'hui et protège l\'habitude.|L\'élan autour de l\'hydratation quotidienne s\'essouffle. Garde-le vivant en buvant de l\'eau aujourd\'hui.|Ne laisse pas l\'hydratation quotidienne devenir irrégulière. Concentre-toi et hydrate-toi aujourd\'hui.|Tu voulais commencer à boire assez d\'eau pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Generic =>
      'Tu as ajouté cette habitude pour une bonne raison. Ne la laisse pas glisser maintenant.|L\'élan de cette habitude s\'essouffle. Présente-toi aujourd\'hui et garde-la vivante.|Tu prends du retard sur cette habitude. Concentre-toi et fais ta répétition.|Ne négocie pas avec la paresse ici. Protège cette habitude aujourd\'hui.|Tu es allé trop loin pour laisser cette habitude dériver. Reste régulier aujourd\'hui.';

  @override
  String get insightStrengthStartSmallType1GoToBedEarly =>
      'Ton habitude de te coucher tôt faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme pour te coucher tôt. Règle une alarme et couche-toi à l\'heure ce soir.|L\'élan pour te coucher tôt s\'essouffle. Garde-le vivant en te couchant à l\'heure ce soir.|Ne laisse pas l\'heure du coucher devenir irrégulière. Concentre-toi et couche-toi à l\'heure ce soir.|Tu voulais commencer à te coucher tôt pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Gym =>
      'Ton habitude d\'entraînement en salle faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme avec ta routine en salle. Va à la salle aujourd\'hui et protège l\'habitude.|L\'élan de ta routine en salle s\'essouffle. Garde-le vivant en t\'entraînant aujourd\'hui.|Ne laisse pas ta routine en salle devenir irrégulière. Concentre-toi et entraîne-toi aujourd\'hui.|Tu voulais construire ta routine en salle pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Medications =>
      'Ton habitude de prendre tes médicaments faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme avec la prise de tes médicaments. Prends-les aujourd\'hui et protège l\'habitude.|L\'élan de la prise de tes médicaments s\'essouffle. Garde-le vivant en les prenant à l\'heure aujourd\'hui.|Ne laisse pas ton planning de médicaments devenir irrégulier. Concentre-toi et prends-les aujourd\'hui.|Tu as commencé à prendre tes médicaments à l\'heure pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Nutrition =>
      'Ton habitude de plan alimentaire faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme avec ton plan alimentaire. Suis ton plan aujourd\'hui et protège l\'habitude.|L\'élan de ton plan alimentaire s\'essouffle. Garde-le vivant en suivant ton plan aujourd\'hui.|Ne laisse pas ton plan alimentaire devenir irrégulier. Concentre-toi et suis-le aujourd\'hui.|Tu voulais commencer ton plan alimentaire pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Praying =>
      'Ton habitude de prière faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme de la prière régulière. Prie aujourd\'hui et protège l\'habitude.|L\'élan de la prière régulière s\'essouffle. Garde-le vivant en priant aujourd\'hui.|Ne laisse pas la prière régulière devenir irrégulière. Concentre-toi et prie aujourd\'hui.|Tu voulais commencer la prière régulière pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1ProductivitySession =>
      'Ton habitude des sessions de productivité faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme de tes sessions de productivité. Fais une session concentrée aujourd\'hui et protège l\'habitude.|L\'élan de tes sessions de productivité s\'essouffle. Garde-le vivant en faisant une session aujourd\'hui.|Ne laisse pas tes sessions de productivité devenir irrégulières. Concentre-toi et fais un bloc concentré aujourd\'hui.|Tu voulais commencer tes sessions de productivité pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Read =>
      'Ton habitude de lecture faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme de ton habitude de lecture. Lis quelques pages aujourd\'hui et protège l\'habitude.|L\'élan de ta lecture s\'essouffle. Garde-le vivant en lisant quelque chose aujourd\'hui.|Ne laisse pas ton habitude de lecture devenir irrégulière. Concentre-toi et lis aujourd\'hui.|Tu voulais commencer ton habitude de lecture pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Research =>
      'Ton habitude de recherche faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme de ton habitude de recherche. Fais un peu de recherche aujourd\'hui et protège l\'habitude.|L\'élan de ton habitude de recherche s\'essouffle. Garde-le vivant en faisant de la recherche aujourd\'hui.|Ne laisse pas ton habitude de recherche devenir irrégulière. Concentre-toi et fais ta recherche aujourd\'hui.|Tu voulais commencer ton habitude de recherche pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Running =>
      'Ta routine de course faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme de ta routine de course. Va courir aujourd\'hui et protège l\'habitude.|L\'élan de ta routine de course s\'essouffle. Garde-le vivant en allant courir aujourd\'hui.|Ne laisse pas ta routine de course devenir irrégulière. Concentre-toi et cours aujourd\'hui.|Tu voulais construire ta routine de course pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Shower =>
      'Ton habitude de la douche faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme de ta douche quotidienne. Prends ta douche aujourd\'hui et protège l\'habitude.|L\'élan de la douche quotidienne s\'essouffle. Garde-le vivant en prenant ta douche aujourd\'hui.|Ne laisse pas ta routine de douche devenir irrégulière. Concentre-toi et prends ta douche aujourd\'hui.|Tu voulais commencer à te doucher régulièrement pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1SkinCare =>
      'Ta routine soin de la peau faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme de ta routine soin de la peau. Fais tes soins aujourd\'hui et protège l\'habitude.|L\'élan de ta routine soin de la peau s\'essouffle. Garde-le vivant en faisant tes soins aujourd\'hui.|Ne laisse pas ta routine soin de la peau devenir irrégulière. Concentre-toi et fais-la aujourd\'hui.|Tu voulais commencer ta routine soin de la peau pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Studying =>
      'Ton habitude d\'étude faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme de ton habitude d\'étude. Étudie aujourd\'hui et protège l\'habitude.|L\'élan de ton habitude d\'étude s\'essouffle. Garde-le vivant en étudiant aujourd\'hui.|Ne laisse pas ton habitude d\'étude devenir irrégulière. Concentre-toi et étudie aujourd\'hui.|Tu voulais commencer ton habitude d\'étude pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1WakeUpEarly =>
      'Ton habitude de te lever tôt faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme pour te lever tôt. Règle ton réveil et lève-toi à l\'heure demain.|L\'élan pour te lever tôt s\'essouffle. Garde-le vivant en te levant à l\'heure demain.|Ne laisse pas le lever tôt devenir irrégulier. Concentre-toi et règle ton réveil ce soir.|Tu voulais commencer à te lever tôt pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Walk =>
      'Ta routine de marche faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme de ta routine de marche. Va marcher aujourd\'hui et protège l\'habitude.|L\'élan de ta routine de marche s\'essouffle. Garde-le vivant en allant marcher aujourd\'hui.|Ne laisse pas ta routine de marche devenir irrégulière. Concentre-toi et marche aujourd\'hui.|Tu voulais construire ta routine de marche pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String get insightStrengthStartSmallType1Work =>
      'Ton habitude de travail faiblit. Ne laisse pas cette routine tomber maintenant.|Tu as perdu le rythme de ton habitude de travail. Fais un travail utile aujourd\'hui et protège l\'habitude.|L\'élan de ton habitude de travail s\'essouffle. Garde-le vivant en travaillant aujourd\'hui.|Ne laisse pas ton habitude de travail devenir irrégulière. Concentre-toi et fais ton travail aujourd\'hui.|Tu voulais construire ton habitude de travail pour une bonne raison. Reste discipliné et ne laisse pas l\'habitude s\'effacer.';

  @override
  String insightStrengthStartSmallType2BrushTeeth(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité avec le brossage des dents a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Le brossage des dents a été plus difficile récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité au brossage des dents a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger le brossage des dents, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Le brossage des dents a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2DrinkWater(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité à bien t\'hydrater a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|L\'hydratation quotidienne a été plus difficile récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité d\'hydratation a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton hydratation, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|L\'hydratation quotidienne a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Generic(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'La régularité a baissé sur cette habitude. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour stabiliser à nouveau.|Tu as perdu le fil ces derniers temps. La force a baissé de $drop%. Essaie ce changement d\'objectif : $fromValue -> $toValue pour retrouver ton rythme.|Les performances récentes décrochent. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour revenir sur la bonne voie.|Cette habitude a besoin d\'un objectif plus léger pour l\'instant. La force a baissé de $drop%. Passe de $fromValue à $toValue pour améliorer la régularité.|Le signal de cette habitude s\'est affaibli récemment. La force a baissé de $drop%. Objectif recommandé : $fromValue -> $toValue pour rester régulier.';
  }

  @override
  String insightStrengthStartSmallType2GoToBedEarly(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité pour te coucher tôt a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Se coucher tôt a été plus difficile récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité sur l\'heure du coucher a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton heure de coucher, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Se coucher tôt a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Gym(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité avec ta routine en salle a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Ta routine en salle a été plus faible récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité en salle a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ta routine en salle, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ta routine en salle a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Medications(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité à prendre tes médicaments à l\'heure a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Prendre tes médicaments à l\'heure a été plus difficile récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité avec les médicaments a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton habitude des médicaments, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ton habitude des médicaments a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Nutrition(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité avec ton plan alimentaire a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Ton plan alimentaire a été plus faible récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité alimentaire a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton plan alimentaire, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ton plan alimentaire a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Praying(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité dans la prière a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|La prière régulière a été plus difficile récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité dans la prière a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton habitude de prière, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ton habitude de prière a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2ProductivitySession(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité dans tes sessions de productivité a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Tes sessions de productivité ont été plus faibles récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité de productivité a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger tes sessions de productivité, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Tes sessions de productivité ont besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Read(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité dans ton habitude de lecture a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Ton habitude de lecture a été plus faible récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité en lecture a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton habitude de lecture, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ton habitude de lecture a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Research(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité dans ton habitude de recherche a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Ton habitude de recherche a été plus faible récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité en recherche a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton habitude de recherche, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ton habitude de recherche a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Running(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité avec ta routine de course a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Ta routine de course a été plus faible récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité en course a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ta routine de course, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ta routine de course a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Shower(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité à prendre ta douche a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Prendre ta douche a été plus difficile récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité des douches a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton habitude de douche, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ton habitude de douche a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2SkinCare(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité avec ta routine soin de la peau a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Ta routine soin de la peau a été plus faible récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité soin de la peau a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ta routine soin de la peau, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ta routine soin de la peau a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Studying(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité dans ton habitude d\'étude a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Ton habitude d\'étude a été plus faible récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité d\'étude a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton habitude d\'étude, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ton habitude d\'étude a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2WakeUpEarly(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité à te lever tôt a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Te lever tôt a été plus difficile récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité matinale a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton habitude de lever tôt, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Le lever tôt a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Walk(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité avec ta routine de marche a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Ta routine de marche a été plus faible récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité en marche a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ta routine de marche, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ta routine de marche a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String insightStrengthStartSmallType2Work(
    Object drop,
    Object fromValue,
    Object toValue,
  ) {
    return 'Ta régularité avec ton habitude de travail a fléchi ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour garder l\'habitude vivante.|Ton habitude de travail a été plus faible récemment. La force a baissé de $drop%. Passe ton objectif de $fromValue à $toValue pour retrouver la régularité.|Ta régularité au travail a baissé ces derniers temps. La force a baissé de $drop% ces derniers jours. Objectif recommandé : $fromValue -> $toValue pour retrouver ton élan.|Pour protéger ton habitude de travail, baisse l\'objectif pour l\'instant. La force a baissé de $drop%. Recommandé : $fromValue -> $toValue.|Ton habitude de travail a besoin d\'un nouveau départ. La force a baissé de $drop%. Essaie $fromValue -> $toValue pour que cette habitude reste vivante.';
  }

  @override
  String get invalidTime => 'Heure invalide';

  @override
  String get keepYourDataSafeByBackingItUpToGoogleDrive =>
      'Protège tes données en les sauvegardant sur Google Drive.';

  @override
  String get label => 'Étiquette';

  @override
  String get leaveSetup => 'Quitter la configuration ?';

  @override
  String get logDuration => 'Enregistrer la durée';

  @override
  String get logProgress => 'Enregistrer la progression';

  @override
  String get makesWidgetsLookMoreGlassy =>
      'Donne un aspect plus verre aux widgets';

  @override
  String get manageYourNotificationPreferences =>
      'Gère tes préférences de notification';

  @override
  String get manageYourSubscriptionsAndBillingPlansHere =>
      'Gère ici tes abonnements et formules de facturation.';

  @override
  String get manageYourSubscriptionsAndViewPremiumBenefits =>
      'Gère tes abonnements et consulte les avantages premium';

  @override
  String get midday => 'Midi';

  @override
  String get middayCheckinTimeForYourHabits =>
      'Moment du bilan de midi pour tes habitudes';

  @override
  String get minutes => 'Minutes';

  @override
  String get missingPermissions => 'Autorisations manquantes';

  @override
  String get mon => 'Lun';

  @override
  String get moreOptions => 'Plus d\'options';

  @override
  String get never => 'Jamais';

  @override
  String get newHabit => 'Nouvelle habitude';

  @override
  String get noHabitsFoundUsingDefaultCategoryOrder =>
      'Aucune habitude trouvée, ordre des catégories par défaut utilisé.';

  @override
  String get noHabitsYet => 'Aucune habitude pour le moment.';

  @override
  String get noOfferingsAvailable => 'Aucune offre disponible';

  @override
  String get noTag => 'Aucune étiquette';

  @override
  String get notCompleted => 'Non terminée';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get notes => 'Notes';

  @override
  String notificationAmountLabelFocus(Object label, Object target) {
    return 'Ton objectif du jour est $target $label.|Ton chiffre pour aujourd\'hui : $target $label. Commence par une première étape.|Dose du jour : $target $label. Objectif clair, exécution simple.|Aujourd\'hui, il faut $target $label. Tu connais le rythme.|Objectif du jour : $target $label. Un but précis est un déclencheur puissant.';
  }

  @override
  String notificationCombinedAmountAlmostDone(
    Object encouragement,
    Object remaining,
  ) {
    return 'Plus que $remaining, $encouragement.';
  }

  @override
  String get notificationCombinedAmountCompleted =>
      'Objectif déjà atteint, bravo.|Tu as terminé l\'objectif du jour, félicitations !|Tu as déjà atteint ton objectif aujourd\'hui, excellent travail !|L\'objectif est déjà atteint, génial !|Tu as déjà atteint l\'objectif du jour, travail impeccable !';

  @override
  String notificationCombinedAmountInProgress(
    Object encouragement,
    Object progress,
  ) {
    return 'Tu en es à $progress, $encouragement.';
  }

  @override
  String notificationCombinedAmountNotStarted(Object encouragement) {
    return 'Commence maintenant, même une seule étape compte, $encouragement.';
  }

  @override
  String notificationCombinedDurationAlmostDone(
    Object encouragement,
    Object remaining,
  ) {
    return 'Plus que $remaining, $encouragement.';
  }

  @override
  String notificationCombinedDurationCompleted(Object encouragement) {
    return 'Objectif déjà atteint, $encouragement.';
  }

  @override
  String notificationCombinedDurationInProgress(
    Object encouragement,
    Object progress,
  ) {
    return 'Tu en es à $progress, $encouragement.';
  }

  @override
  String notificationCombinedDurationNotStarted(Object encouragement) {
    return 'Lance une courte session maintenant, $encouragement.';
  }

  @override
  String notificationCombinedFresh(Object days, Object encouragement) {
    return 'Tu as commencé cette habitude il y a $days jours, $encouragement.';
  }

  @override
  String notificationCombinedGeneral(Object encouragement) {
    return '$encouragement.';
  }

  @override
  String notificationCombinedOneOff(Object encouragement, Object period) {
    return 'Ne rate pas aujourd\'hui, c\'est ta dernière chance $period et $encouragement.';
  }

  @override
  String get notificationEncourageBrushTeeth1 =>
      'garder ta série d\'hygiène bien solide';

  @override
  String get notificationEncourageBrushTeeth2 =>
      'protéger ta routine avec une petite victoire rapide';

  @override
  String get notificationEncourageBrushTeeth3 =>
      'rester régulier avec les soins de base';

  @override
  String get notificationEncourageDrinkWater1 =>
      'une bonne hydratation soutient maintenant tout ton organisme';

  @override
  String get notificationEncourageDrinkWater2 =>
      'un verre maintenant stabilise ton énergie';

  @override
  String get notificationEncourageDrinkWater3 =>
      'de petites doses d\'eau améliorent tes performances au quotidien';

  @override
  String get notificationEncourageGeneric1 =>
      'te montrer aujourd\'hui fait vivre l\'habitude';

  @override
  String get notificationEncourageGeneric2 =>
      'une petite action maintenant protège ton élan';

  @override
  String get notificationEncourageGeneric3 =>
      'la régularité aujourd\'hui facilite demain';

  @override
  String get notificationEncourageGoToBedEarly1 =>
      'protéger ta soirée rend demain plus léger';

  @override
  String get notificationEncourageGoToBedEarly10 =>
      'cette décision du soir aide toute ta semaine à se dérouler plus facilement';

  @override
  String get notificationEncourageGoToBedEarly2 =>
      'te coucher plus tôt te donne un démarrage plus clair demain';

  @override
  String get notificationEncourageGoToBedEarly3 =>
      'ce choix ce soir prépare un meilleur matin';

  @override
  String get notificationEncourageGoToBedEarly4 =>
      'la régularité du sommeil porte ses fruits toute la journée de demain';

  @override
  String get notificationEncourageGoToBedEarly5 =>
      'une routine calme le soir protège ton énergie';

  @override
  String get notificationEncourageGoToBedEarly6 =>
      'finir la journée à l\'heure garde ton rythme stable';

  @override
  String get notificationEncourageGoToBedEarly7 =>
      'un meilleur horaire de sommeil est un avantage discret pour ta performance';

  @override
  String get notificationEncourageGoToBedEarly8 =>
      'éteindre les lumières plus tôt maintient ta récupération sur la bonne voie';

  @override
  String get notificationEncourageGoToBedEarly9 =>
      'une petite discipline au moment du coucher crée des matins plus forts';

  @override
  String get notificationEncourageGym1 =>
      'une séance aujourd\'hui garde ton niveau élevé';

  @override
  String get notificationEncourageGym2 =>
      'te présenter maintenant protège ton élan de force';

  @override
  String get notificationEncourageGym3 =>
      'la séance du jour s\'accumule avec le temps';

  @override
  String get notificationEncourageMedications1 =>
      'bien gérer ce moment protège ta routine de santé';

  @override
  String get notificationEncourageMedications2 =>
      'suivre le planning garde ta base stable';

  @override
  String get notificationEncourageMedications3 =>
      'cette étape soutient ton bien-être à long terme';

  @override
  String get notificationEncourageNutrition1 =>
      'un choix délibéré maintenant soutient ta base';

  @override
  String get notificationEncourageNutrition2 =>
      'les petites victoires nutritionnelles s\'additionnent vite';

  @override
  String get notificationEncourageNutrition3 =>
      'la régularité ici améliore tout le reste';

  @override
  String get notificationEncourageProductivitySession1 =>
      'une session concentrée protège ton temps de travail profond';

  @override
  String get notificationEncourageProductivitySession2 =>
      'un bloc de concentration maintenant peut changer ta journée';

  @override
  String get notificationEncourageProductivitySession3 =>
      'la régularité dans la concentration améliore le rendement';

  @override
  String get notificationEncourageRead1 =>
      'quelques pages maintenant gardent ton identité de lecteur forte';

  @override
  String get notificationEncourageRead2 =>
      'la lecture quotidienne, même petite, mène à de vrais progrès';

  @override
  String get notificationEncourageRead3 =>
      'te montrer aujourd\'hui fait vivre la série';

  @override
  String get notificationEncourageResearch1 =>
      'une découverte aujourd\'hui fait avancer ton travail';

  @override
  String get notificationEncourageResearch2 =>
      'une exploration régulière mène à la clarté';

  @override
  String get notificationEncourageResearch3 =>
      'noter une seule découverte maintenant garde l\'élan';

  @override
  String get notificationEncourageRunning1 =>
      'un entraînement aujourd\'hui développe l\'endurance';

  @override
  String get notificationEncourageRunning2 =>
      'te présenter maintenant renforce ta base de course';

  @override
  String get notificationEncourageRunning3 =>
      'cet effort rend ton élan sportif réel';

  @override
  String get notificationEncourageShower1 =>
      'une petite remise à zéro peut relancer ta concentration';

  @override
  String get notificationEncourageShower2 =>
      'cette routine t\'aide à te sentir dynamique';

  @override
  String get notificationEncourageShower3 =>
      'une remise à zéro nette permet à ta journée d\'avancer';

  @override
  String get notificationEncourageSkinCare1 =>
      'protège ta peau avec une étape régulière';

  @override
  String get notificationEncourageSkinCare2 =>
      'fais de la régularité ton atout pour la peau';

  @override
  String get notificationEncourageSkinCare3 =>
      'garde ta routine fiable et simple';

  @override
  String get notificationEncourageStudying1 =>
      'un bloc concentré maintenant développe ton élan d\'apprentissage';

  @override
  String get notificationEncourageStudying2 =>
      'te présenter aujourd\'hui fait grandir tes connaissances';

  @override
  String get notificationEncourageStudying3 =>
      'de courtes sessions régulières battent le bachotage';

  @override
  String get notificationEncourageWakeUpEarly1 =>
      'commencer ta journée avec intention';

  @override
  String get notificationEncourageWakeUpEarly2 =>
      'garder ton rythme matinal régulier';

  @override
  String get notificationEncourageWakeUpEarly3 =>
      't\'offrir un démarrage plus calme';

  @override
  String get notificationEncourageWalk1 =>
      'une courte marche suffit à garder l\'élan';

  @override
  String get notificationEncourageWalk2 =>
      'bouger maintenant aide ton énergie et ta concentration';

  @override
  String get notificationEncourageWalk3 =>
      'ce geste simple soutient la régularité à long terme';

  @override
  String get notificationEncourageWork1 =>
      'commencer maintenant crée une vraie traction';

  @override
  String get notificationEncourageWork2 =>
      'une poussée significative peut débloquer ta journée';

  @override
  String get notificationEncourageWork3 =>
      'une exécution régulière garde les progrès visibles';

  @override
  String get notificationFallbackGeneric =>
      'De petites actions aujourd\'hui créent un élan à long terme.';

  @override
  String get notificationFallbackTitle => 'Rappel d\'habitude';

  @override
  String get notificationFreshnessBrandNew =>
      'C\'est le moment pour cette toute nouvelle habitude de briller !';

  @override
  String notificationFreshnessEstablishedDays(Object days) {
    return 'Tu construis ceci depuis $days jours. Continue à accumuler les victoires.';
  }

  @override
  String notificationFreshnessNewDays(Object days) {
    return 'Tu as commencé il y a $days. Continue comme ça !|Jour $days. Les premiers jours sont la base, beau travail.|Tu as commencé il y a $days jours. Chacun compte autant.';
  }

  @override
  String get notificationOptional =>
      'Celle-ci est facultative aujourd\'hui, mais tu veux bien l\'essayer quand même ?|Tu as un peu de temps en plus ?';

  @override
  String get notificationPeriodMonthly => 'mensuelle';

  @override
  String get notificationPeriodWeekly => 'hebdomadaire';

  @override
  String get notificationPremadeBrushTeeth =>
      'Une petite victoire d\'hygiène maintenant garde ta routine au top.';

  @override
  String get notificationPremadeDrinkWater =>
      'Hydrate-toi maintenant et garde ton corps en forme.';

  @override
  String get notificationPremadeGoToBedEarly =>
      'Protège ta soirée de ce soir pour que demain commence plus facilement.';

  @override
  String get notificationPremadeGym =>
      'Présente-toi à une bonne séance de salle et installe ta régularité.';

  @override
  String get notificationPremadeMedications =>
      'Prends tes médicaments à l\'heure pour protéger ta santé.';

  @override
  String get notificationPremadeNutrition =>
      'Fais un choix alimentaire réfléchi dès maintenant.';

  @override
  String get notificationPremadePraying =>
      'Prends un moment calme maintenant et reconnecte-toi avec intention.';

  @override
  String get notificationPremadeProductivitySession =>
      'Lance une session concentrée et protège ton temps de travail profond.';

  @override
  String get notificationPremadeRead =>
      'Lis un peu maintenant et laisse la régularité faire le reste.';

  @override
  String get notificationPremadeResearch =>
      'Note un insight utile et fais avancer tes recherches.';

  @override
  String get notificationPremadeRunning =>
      'Enfile tes chaussures et fais une bonne séance d\'entraînement aujourd\'hui.';

  @override
  String get notificationPremadeShower =>
      'Recharge ton énergie avec cette routine simple.';

  @override
  String get notificationPremadeSkinCare =>
      'Prends soin de ta peau maintenant pour rester régulier.';

  @override
  String get notificationPremadeStudying =>
      'Lance un bloc d\'étude concentré et prends de l\'élan dans ton apprentissage.';

  @override
  String get notificationPremadeWakeUpEarly =>
      'Un bon début de journée commence avec ce choix.';

  @override
  String get notificationPremadeWalk =>
      'Une courte marche maintenant suffit pour garder l\'élan.';

  @override
  String get notificationPremadeWork =>
      'Commence ta tâche la plus importante et prends de la vitesse.';

  @override
  String notificationProgressAlmostDoneAmount(Object label, Object remaining) {
    return 'Tu y es presque. Il ne reste plus que $remaining $label.|Il reste $remaining $label. C\'est ton rythme, laisse-toi porter.|Encore $remaining $label. Tu as déjà fait la majeure partie.|Presque là : $remaining $label te séparent de la fin.|Il te reste $remaining $label pour atteindre ton objectif. Termine en beauté.|La ligne d\'arrivée est proche. Plus que $remaining $label à boucler.';
  }

  @override
  String notificationProgressAlmostDoneDuration(Object remaining) {
    return 'Plus que $remaining. Encore un petit effort et c\'est fini !|Encore $remaining. Tu peux toujours en faire un tout petit peu plus.|Il reste $remaining. Finir est déjà une récompense en soi.|Encore $remaining. Tu peux le faire !';
  }

  @override
  String notificationProgressCompletedAmount(Object completed, Object label) {
    return 'Tu as déjà atteint $completed $label. Prêt pour plus ?|$completed $label faits. L\'élan est de ton côté maintenant.|$completed $label dans la poche. Ton habitude fonctionne.|Bien joué : $completed $label terminés. Tu veux aller un peu plus loin ?';
  }

  @override
  String notificationProgressCompletedDuration(Object completed) {
    return 'Objectif atteint : $completed déjà faits.|Objectif de temps atteint : $completed. Tu es venu et tu as tenu bon.|$completed de temps concentré. Terminé. C\'est un vrai engagement.|Session terminée : $completed. Ta régularité vient de progresser.|$completed enregistrés. Ton futur toi te remerciera.|Temps cible atteint : $completed. Très bel usage de ton effort concentré.';
  }

  @override
  String notificationProgressInProgressAmount(
    Object completed,
    Object label,
    Object remaining,
    Object target,
  ) {
    return '$completed sur $target $label. Lance-toi !|Tu as déjà enregistré $completed $label. Excellent début.|$completed/$target $label pour l\'instant. Garde un rythme régulier.|$completed faits, $remaining restants. Tu peux le faire.|$completed sur $target. Continue !';
  }

  @override
  String notificationProgressInProgressDuration(
    Object completed,
    Object target,
  ) {
    return '$completed pour l\'instant, ton objectif est $target, continue comme ça !|Tu as fait le plus dur : te lancer. Continue sur ta lancée.|Tu as enregistré $completed sur $target. Reste dans ta bulle.|$completed sur $target terminés. C\'est bien, continue !';
  }

  @override
  String get notificationProgressNoTracking =>
      'Une petite action maintenant fait vivre cette habitude.|Ne laisse pas cette habitude s\'éteindre, un petit effort maintenant protège ton élan.|La régularité aujourd\'hui rend demain plus facile. Tu veux essayer ?|N\'oublie pas ton habitude aujourd\'hui !|Une petite action maintenant garde ton habitude solide.|Hé ! C\'est l\'heure de ton habiiitude !|Un petit pas fait vivre la série.|Fait vaut mieux que parfait. Lance-toi.|La régularité s\'accumule. Un jour de plus compte.|Ton habitude est une promesse faite à toi-même. Tiens-la.|Même habitude, un jour de plus en force. Continue de construire.|Pas besoin de motivation. Commence, c\'est tout.|Vois ça comme un cadeau pour ton futur toi. Lance-toi !|Tu construis quelque chose d\'important. Continue.|Tu prends le temps pour ce qui compte. C\'est toi.|Curieux de voir ce qui se passe quand tu ne sautes jamais une fois ?|Notification d\'habitude : quel est ton prochain coup ?|C\'est le moment de passer à l\'action.|Ne casse pas la chaîne. Encore un jour.|Pas besoin d\'être parfait. Il suffit d\'être présent.|Petites actions aujourd\'hui = grands résultats demain.';

  @override
  String notificationProgressNotStartedAmount(Object label) {
    return 'Commence avec seulement 1 $label et prends de l\'élan. C\'est facile !|Pas besoin de motivation. Commence, c\'est tout.|La partie la plus dure, c\'est de commencer. Tu peux le faire !';
  }

  @override
  String get notificationProgressNotStartedDuration =>
      'Commence au moins par une courte session !|Pas besoin de motivation. Commence, c\'est tout.|La partie la plus dure, c\'est de commencer. Tu peux le faire !|Dans quelques minutes, tu seras content d\'avoir commencé.';

  @override
  String notificationScheduleCustomEveryDays(Object days) {
    return 'Rythme personnalisé : tous les $days jours. Aujourd\'hui fait partie de tes créneaux.|Rythme de tous les $days jours. Aujourd\'hui est un jour prévu.|Ton cycle de $days jours tombe aujourd\'hui. C\'est le moment d\'agir.|Ton planning personnalisé le dit : aujourd\'hui est le jour de cette habitude. Profites-en !|Cette habitude se répète tous les $days jours. C\'est ton tour maintenant.|Aujourd\'hui fait partie du rythme de cette habitude. Respecte le schéma.';
  }

  @override
  String get notificationScheduleDaily =>
      'Ton rendez-vous quotidien t\'attend. Verrouille-le.|Le créneau du jour est ouvert. Lance-toi.|Ta pratique quotidienne se construit en silence. Mais elle se construit.|C\'est ton appel quotidien. Réponds-y !';

  @override
  String notificationScheduleMonthlyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  ) {
    return 'Il te faut encore $remaining ce mois-ci ($completed/$target faits). Sauter aujourd\'hui met ton objectif en danger.|Encore $remaining ce mois-ci ($completed/$target). Aujourd\'hui protège tes progrès.|Ton objectif mensuel ($completed/$target) reste possible. Aujourd\'hui est un coup clé.|$completed/$target pour le mois. Ne laisse pas aujourd\'hui creuser l\'écart.|Il reste $remaining ce mois-ci ($completed/$target). Une séance à la fois, et tu restes sur la bonne voie.|Objectif mensuel à portée ($completed/$target). Aujourd\'hui garde la porte ouverte.';
  }

  @override
  String notificationScheduleMonthlyImpossible(
    Object completed,
    Object target,
  ) {
    return 'L\'objectif de ce mois ne sera pas atteint ($completed/$target). Utilise les jours restants pour pratiquer, pas pour te mettre la pression.|Le chiffre mensuel est hors d\'atteinte ($completed/$target). Mais les habitudes se construisent dans les écarts, pas seulement dans les objectifs.|Objectif inatteignable ce mois-ci ($completed/$target). Chaque tentative reconfigure quand même la boucle.|$completed/$target ce mois-ci. L\'objectif ne sera pas atteint, mais l\'habitude compte toujours.|L\'objectif de ce mois dépasse tes jours disponibles ($completed/$target). Ajuste et continue d\'avancer.';
  }

  @override
  String notificationScheduleMonthlyOneLeft(Object completed, Object target) {
    return 'Encore une réalisation ce mois-ci et tu atteins ton objectif ($completed/$target).|Encore une ce mois-ci et tu atteins $target ($completed faits). C\'est ton coup final.|Tu es à une séance de ton objectif mensuel ($completed/$target). Scelle-le.|L\'objectif mensuel a besoin d\'une dernière réalisation ($completed/$target). Aujourd\'hui peut être ce jour.|Encore une et tu seras à $target pour le mois ($completed faits). Termine ce que tu as commencé.|Ton objectif mensuel n\'est plus qu\'à un pas ($completed/$target). Il ne reste qu\'une séance.';
  }

  @override
  String notificationScheduleMonthlyReached(Object completed, Object target) {
    return 'Objectif mensuel déjà atteint ($completed/$target). Une répétition en plus, un élan en plus.|Tu as réussi ton objectif mensuel ($completed/$target). C\'est une régularité d\'élite.|Objectif mensuel : atteint ($completed/$target). Tout ce qui suit est une croissance exponentielle.|Objectif mensuel déjà explosé ($completed/$target). Les répétitions bonus creusent le sillon.';
  }

  @override
  String notificationScheduleMonthlyRemaining(Object remaining, Object target) {
    return 'Il te faut encore $remaining ce mois-ci pour atteindre $target.|Il reste $remaining séances ce mois-ci pour atteindre $target. Un rythme régulier gagne.|Il te faut encore $remaining pour ton objectif mensuel de $target. Chacune compte.|Objectif mensuel : il reste $remaining sur $target. Tu as le temps, utilise-le bien.|Encore $remaining ce mois-ci pour $target. De petites actions régulières comblent l\'écart.|Ton chiffre mensuel est $target, avec $remaining restants. Aujourd\'hui fait avancer l\'objectif.';
  }

  @override
  String notificationScheduleWeeklyAtRisk(
    Object completed,
    Object remaining,
    Object target,
  ) {
    return 'Il te faut encore $remaining cette semaine ($completed/$target faits). Si tu sautes aujourd\'hui, ton objectif devient bien plus difficile.|Il te faut encore $remaining cette semaine ($completed/$target). Aujourd\'hui, ça reste faisable.|Encore $remaining cette semaine ($completed/$target). Sauter aujourd\'hui ajoute de la pression.|Ton objectif hebdomadaire ($completed/$target) reste atteignable. Aujourd\'hui est un levier.|$completed/$target pour la semaine. Une aujourd\'hui garde ton objectif sur les rails.|Il reste $remaining cette semaine ($completed/$target). Aujourd\'hui est ton meilleur coup.';
  }

  @override
  String notificationScheduleWeeklyImpossible(Object completed, Object target) {
    return 'L\'objectif de cette semaine est hors d\'atteinte ($completed/$target). Chaque répétition prépare quand même la semaine prochaine.|L\'objectif ne sera pas atteint cette semaine ($completed/$target). Mais les semaines inachevées nous apprennent quoi ajuster.|Le chiffre hebdomadaire ne sera pas atteint ($completed/$target). Fais-le quand même : la régularité se moque du tableau des scores.|Objectif manqué cette semaine ($completed/$target). Chaque tentative renforce quand même la boucle de l\'habitude.|$completed/$target cette semaine. L\'objectif est hors de portée, mais l\'habitude, elle, ne l\'est pas.';
  }

  @override
  String notificationScheduleWeeklyOneLeft(Object completed, Object target) {
    return 'Encore une réalisation cette semaine et tu atteins ton objectif ($completed/$target).|Encore une cette semaine et tu seras à $target ($completed faits). Boucle la boucle.|Tu n\'es plus qu\'à une séance de ton objectif hebdomadaire ($completed/$target). Fais-la compter.|L\'objectif de cette semaine n\'a besoin que d\'une de plus ($completed/$target). Tu peux le boucler maintenant.|Une seule réalisation de plus te sépare de $target cette semaine ($completed faits).|Objectif hebdomadaire à portée : encore une ($completed/$target). C\'est juste aujourd\'hui.';
  }

  @override
  String notificationScheduleWeeklyReached(Object completed, Object target) {
    return 'Objectif hebdomadaire déjà atteint ($completed/$target). C\'est de la régularité bonus.|Tu as atteint ton objectif hebdomadaire ($completed/$target). Tout le reste est un plus.|Objectif hebdomadaire : atteint ($completed/$target). Les répétitions bonus forgent des habitudes d\'élite.|$completed/$target pour la semaine. Tu vas bien au-delà.|Objectif hebdomadaire déjà rempli ($completed/$target). Tu es sur un niveau supérieur.|Tu as rempli ton objectif hebdomadaire ($completed/$target). Ta régularité est maintenant un surplus.';
  }

  @override
  String notificationScheduleWeeklyRemaining(Object remaining, Object target) {
    return 'Il te faut encore $remaining cette semaine pour atteindre $target.|Encore $remaining pour l\'objectif hebdomadaire de $target. Un rythme constant fonctionne.|Il te faut encore $remaining cette semaine. Aujourd\'hui est un excellent moment pour en commencer une.|Objectif hebdomadaire : il reste $remaining sur $target. Répartis l\'effort.|Il reste $remaining séances pour atteindre $target cette semaine. Chacune compte autant.|Ton objectif hebdomadaire est $target, il reste $remaining. Un pas à la fois.';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsAreDisabled => 'Les notifications sont désactivées';

  @override
  String get notificationsOffDialogDesc =>
      'Active les notifications pour recevoir des rappels pour cette habitude.';

  @override
  String get turnOn => 'Activer';

  @override
  String get now => 'Maintenant';

  @override
  String get numberOfDaysInARowYouHaveCompletedAllYourHabits =>
      'Nombre de jours consécutifs où tu as terminé toutes tes habitudes.';

  @override
  String
  get onlyVisibleOnDailyPlanEnableColorfulModeInSettingsToShowOnCompletion =>
      'Visible uniquement dans le plan quotidien. Active le mode « Coloré » dans les Paramètres pour l\'afficher à la fin.';

  @override
  String get optOut => 'Se désinscrire';

  @override
  String get optionalHabit => 'Habitude facultative';

  @override
  String get optionalHabits => 'Habitudes facultatives';

  @override
  String get orToChangeLabel => 'ou l\'étiquette de quantité';

  @override
  String get otherHabits => 'Autres habitudes';

  @override
  String get passphrase => 'Phrase de passe';

  @override
  String get perfectDaysStreak => 'Série de jours parfaits';

  @override
  String get preparingBackupName => 'Préparation du nom de la sauvegarde...';

  @override
  String get profile => 'Profil';

  @override
  String get reorderingCategoriesBasedOnTime =>
      'Réorganisation des catégories selon l\'heure';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get resetChanges => 'Réinitialiser les modifications ?';

  @override
  String get sat => 'Sam';

  @override
  String get satoshi => 'Satoshi';

  @override
  String get save => 'Enregistrer';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get schedulingAndAlerts => 'Planification et alertes';

  @override
  String get schedulingFallbackToAll => 'Planification revenue à « Tous »';

  @override
  String get selectAColorPaletteForYourInterface =>
      'Sélectionne une palette de couleurs pour ton interface';

  @override
  String get selectHabitColor => 'Choisis la couleur de l\'habitude';

  @override
  String get selectHabitTime => 'CHOISIS L\'HEURE DE L\'HABITUDE :';

  @override
  String get selectTime => 'Choisir l\'heure';

  @override
  String get selectTimeInterval => 'Choisir l\'intervalle de temps';

  @override
  String get selected => 'Sélectionné';

  @override
  String get setAmountLabel => 'Définir l\'étiquette de quantité';

  @override
  String get setDuration => 'Définir la durée';

  @override
  String get setNotificationTime => 'Définir l\'heure de notification';

  @override
  String get setPassphrase => 'Définir la phrase de passe';

  @override
  String get setSchedule => 'Définir le planning';

  @override
  String get settings => 'Paramètres';

  @override
  String get signinFirstError => 'Erreur : connecte-toi d\'abord';

  @override
  String get skip => 'Passer';

  @override
  String skippedHabitFoundHabitsskippedTotal(Object habitsSkipped) {
    return 'Habitude sautée trouvée, $habitsSkipped au total';
  }

  @override
  String get skippingHabitNotAllowedHabitDayBeforeSkipped =>
      'Saut de l\'habitude non autorisé, l\'habitude a été sautée la veille';

  @override
  String get startTime => 'Heure de début';

  @override
  String get stats => 'Statistiques';

  @override
  String get subscriptions => 'Abonnements';

  @override
  String get sun => 'Dim';

  @override
  String syncErrorErrormessage(Object errorMessage) {
    return 'Erreur de synchronisation : $errorMessage';
  }

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncing => 'Synchronisation...';

  @override
  String syncingProgressmessage(Object progressMessage) {
    return 'Synchronisation : $progressMessage';
  }

  @override
  String get tappedAmount => 'Quantité validée';

  @override
  String get tappedDuration => 'Durée validée';

  @override
  String get thisAmountLabelWillBeRemoved =>
      'Cette étiquette de quantité sera supprimée.';

  @override
  String get thisLabelCantBeDeleted =>
      'Cette étiquette ne peut pas être supprimée';

  @override
  String get thisNotificationCantBeDeleted =>
      'Cette notification ne peut pas être supprimée';

  @override
  String get thisNotificationTimeWillBeRemoved =>
      'Cette heure de notification sera supprimée.';

  @override
  String
  get thisPassphraseIsUsedForYourDataEncryptionSaveItSecurelyYouWillUseItAgainWhenGettingYourDataOnOtherDevices =>
      'Cette phrase de passe sert à chiffrer tes données. Conserve-la en lieu sûr : tu en auras de nouveau besoin pour récupérer tes données sur d\'autres appareils.';

  @override
  String get thisReminderWillTriggerOnlyOnScheduledHabitDays =>
      'Ce rappel ne se déclenchera que les jours prévus pour l\'habitude.';

  @override
  String get thu => 'Jeu';

  @override
  String get time => 'Fois';

  @override
  String get times => 'fois';

  @override
  String get step => 'pas';

  @override
  String get steps => 'pas';

  @override
  String get glass => 'verre';

  @override
  String get glasses => 'verres';

  @override
  String get page => 'page';

  @override
  String get pages => 'pages';

  @override
  String get dl => 'dl';

  @override
  String get km => 'km';

  @override
  String get meal => 'repas';

  @override
  String get meals => 'repas';

  @override
  String get to => 'Pour';

  @override
  String get toReceiveRemindersPleaseEnableNotificationPermissionsForHabitt =>
      'Pour recevoir des rappels, autorise les notifications pour Habitt.';

  @override
  String get toUseHabitRemindersEnableNotificationsInYourDeviceSettings =>
      'Pour utiliser les rappels d\'habitude, active les notifications dans les réglages de ton appareil.';

  @override
  String get tue => 'Mar';

  @override
  String get unknown => 'Inconnu';

  @override
  String get uploadingBackupToCloud => 'Envoi de la sauvegarde dans le cloud !';

  @override
  String get useYourGoogleDriveToBackupEncryptedAppData =>
      'Utilise ton Google Drive pour sauvegarder les données chiffrées de l\'application.';

  @override
  String get wed => 'Mer';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String get welcomeToHabitt => 'Bienvenue sur Habitt.';

  @override
  String get whatAreYouCountingForThisHabit =>
      'Que comptes-tu pour cette habitude ?';

  @override
  String get whatShouldWeCallYou => 'Comment doit-on t\'appeler ?';

  @override
  String get whatsUp => 'Quoi de neuf';

  @override
  String get wrapUp => 'Bilan du soir';

  @override
  String get wrapUpReflectionHowDidYourHabitsGoToday =>
      'Bilan du soir : comment se sont passées tes habitudes aujourd\'hui ?';

  @override
  String get youAreCurrentlyNotConnectedToYourGoogleAccount =>
      'Tu n\'es actuellement pas connecté à ton compte Google.';

  @override
  String youCanPressNumberAbove(Object type) {
    return 'Tu peux aussi appuyer sur le nombre ci-dessus pour changer $type';
  }

  @override
  String get youHaveUnsavedChangesAreYouSureYouWantToGoBackAndDiscardThem =>
      'Tu as des modifications non enregistrées. Es-tu sûr de vouloir revenir en arrière et les abandonner ?';

  @override
  String get youHaventAddedAnyHabitsYet =>
      'Tu n’as encore ajouté aucune habitude';

  @override
  String get youWillUseThisPassphraseToDecryptYourDataWhenImportingIt =>
      'Tu utiliseras cette phrase de passe pour déchiffrer tes données lors de l\'importation.';

  @override
  String get yourName => 'Ton prénom';

  @override
  String get gettingConsistantMakeNonOptional =>
      'Tu deviens vraiment régulier avec cette habitude. Pense à ne plus la rendre facultative pour te pousser un peu plus. Veux-tu mettre cette habitude à jour maintenant ?';

  @override
  String get getPremium => 'Soutenir le projet';

  @override
  String get enjoyAllBenefits =>
      'Profite de tous les avantages de l\'application';

  @override
  String get rateUs => 'Noter l\'application';

  @override
  String get reportBug => 'Signaler un bug';

  @override
  String get leaveFeedback => 'Laisser un avis';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get logOut => 'Se déconnecter';

  @override
  String get backupAndSync => 'Sauvegarde et synchronisation';

  @override
  String lastSynced(Object lastSynced) {
    return 'Dernière synchronisation : $lastSynced';
  }

  @override
  String changeHabitTimesInPeriodWarning(Object period) {
    return 'Changer le nombre de fois où l\'habitude apparaît dans un(e) $period effacera les jours sélectionnés';
  }

  @override
  String get habitDetails => 'Détails de l\'habitude';

  @override
  String get deleteHabit => 'Supprimer l\'habitude';

  @override
  String get markAsComplete => 'Marquer comme terminé';

  @override
  String get habitNotFound => 'Habitude introuvable';

  @override
  String get strength => 'Force';

  @override
  String get skipped => 'Sautée';

  @override
  String get streak => 'Série';

  @override
  String get currentStreak => 'Série en cours';

  @override
  String get longestStreak => 'Plus longue série';

  @override
  String get day => 'jour';

  @override
  String get days => 'jours';

  @override
  String get completionRate => 'Taux de réalisation';

  @override
  String get completionRatio => 'Ratio de réalisation';

  @override
  String get last7Days => '7 derniers jours';

  @override
  String get consistency => 'Régularité';

  @override
  String get yourActivityOverTime => 'Ton activité au fil du temps';

  @override
  String get less => 'Moins';

  @override
  String get more => 'Plus';

  @override
  String get allHabits => 'Toutes les habitudes';

  @override
  String get isScheduledToday => 'Prévue aujourd\'hui';

  @override
  String get time2 => 'Heure';

  @override
  String get chooseIcon => 'Choisir une icône';

  @override
  String get schedule => 'Planning';

  @override
  String get habitType => 'Type d\'habitude';

  @override
  String get select => 'Sélectionner';

  @override
  String get repeatEvery => 'Répéter tous les :';

  @override
  String habitWillAppear(Object dayLabel, Object days) {
    return 'Cette habitude apparaîtra tous les $days. $dayLabel à partir d\'aujourd\'hui';
  }

  @override
  String get language => 'Langue';

  @override
  String get chooseAppLanguage => 'Choisis la langue de l\'application';

  @override
  String get appearance => 'Apparence';

  @override
  String get mode => 'Mode';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get system => 'Système';

  @override
  String get preferences => 'Préférences';

  @override
  String get allNotifications => 'Toutes les notifications';

  @override
  String get habitNotifications => 'Notifications d\'habitudes';

  @override
  String get notificationSettings => 'Paramètres des notifications';

  @override
  String get dailyReminders => 'Rappels quotidiens';

  @override
  String get next => 'Suivant';

  @override
  String get findALanguage => 'Rechercher une langue';

  @override
  String get noLanguagesFound => 'Aucune langue trouvée';

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get weekly => 'Hebdomadaire';

  @override
  String get week => 'semaine';

  @override
  String get timesPerWeek => 'Fois par semaine :';

  @override
  String get timesPerMonth => 'Fois par mois :';

  @override
  String get monthly => 'Mensuel';

  @override
  String get month => 'mois';

  @override
  String habitWillAppearWeekly(Object amount, Object label) {
    return 'Cette habitude apparaîtra $amount $label par semaine jusqu\'à ce qu\'elle soit terminée';
  }

  @override
  String habitWillAppearMonthly(Object amount, Object label) {
    return 'Cette habitude apparaîtra $amount $label par mois jusqu\'à ce qu\'elle soit terminée';
  }

  @override
  String get selectDaysForHabit => 'Sélectionne les jours de cette habitude :';

  @override
  String leaveUnselected(Object period) {
    return 'Laisse vide si tu veux que l\'habitude apparaisse chaque jour de la période ($period) jusqu\'à ce que les objectifs soient atteints';
  }

  @override
  String get month2 => 'mois';

  @override
  String get week2 => 'semaine';

  @override
  String get target => 'Objectif';

  @override
  String get name => 'Nom';

  @override
  String get uploadPhoto => 'Importer une photo';

  @override
  String get profileDetails => 'Détails du profil';

  @override
  String get email => 'E-mail';

  @override
  String get youDontHaveAnEmailYet => 'Tu n\'as pas encore d\'e-mail';

  @override
  String get yourUsername => 'Ton nom d\'utilisateur';

  @override
  String get youreDoingGreat => 'Tu t\'en sors vraiment bien !';

  @override
  String get onboardingStep1Title => 'Crée des habitudes qui tiennent vraiment';

  @override
  String get onboardingStep1Subtitle =>
      'Suis tes progrès. Reste régulier. Vois ta progression au fil du temps.';

  @override
  String get onboardingStep2Title => 'Suis tes habitudes à ta façon';

  @override
  String get onboardingStep2Subtitle =>
      'Compte les répétitions, mesure la durée ou marque simplement ton habitude comme terminée.';

  @override
  String get onboardingStep3Title => 'Vois ta vraie régularité';

  @override
  String get onboardingStep3Subtitle =>
      'Séries, force, ratio hebdomadaire et analyses de progrès au même endroit.';

  @override
  String get onboardingStep4Title => 'Reste sur la bonne voie';

  @override
  String get onboardingStep4Subtitle =>
      'Rappels du matin, de midi et du soir, avec un contrôle total.';

  @override
  String get getStarted => 'Commencer';

  @override
  String get onboardingDemoHabitStudying => 'Étudier';

  @override
  String get onboardingDemoHabitBrushTeeth => 'Se brosser les dents';

  @override
  String get onboardingDemoHabitReadBook => 'Lire un livre';

  @override
  String get onboardingDemoHabitPushUps => 'Pompes';

  @override
  String get supportDeveloper =>
      'Aide à garder l\'application gratuite et à la faire grandir';

  @override
  String get autoBackup => 'Synchronisation et sauvegarde automatiques';

  @override
  String get backUpNow => 'Sauvegarder maintenant';

  @override
  String get restoreFromBackup => 'Restaurer depuis une sauvegarde';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get keepHabitsSafe => 'Garde tes habitudes et tes progrès en sécurité';

  @override
  String get neverBackedUp => 'Jamais';

  @override
  String get migrateToSeamlessSync => 'Migrer vers une synchronisation fluide';

  @override
  String get legacyBackupDescription =>
      'Ta sauvegarde utilise une ancienne phrase de passe. Saisis-la une fois pour passer à une synchronisation fluide, sans mot de passe. Tu n\'en auras plus besoin ensuite.';

  @override
  String get migrate => 'Migrer';

  @override
  String get enterOldPassphrase => 'Saisir l\'ancienne phrase de passe';

  @override
  String get syncFailed => 'Échec de la synchronisation';

  @override
  String get disconnectGoogle => 'Déconnecter Google';

  @override
  String get restoreWithDeltasTitle => 'Inclure les modifications récentes ?';

  @override
  String get restoreWithDeltasDesc =>
      'Des modifications faites après cette sauvegarde existent sur ton Drive. Tu peux les inclure par-dessus la sauvegarde restaurée, ou restaurer la sauvegarde telle quelle.';

  @override
  String get restoreWithDeltasInclude => 'Inclure les modifications';

  @override
  String get restoreWithDeltasSkip => 'Restaurer uniquement';

  @override
  String get restoreConfirmTitle => 'Restaurer depuis la sauvegarde ?';

  @override
  String get restoreConfirmDesc =>
      'Tes données seront entièrement remplacées par cette sauvegarde. Tout ce que tu as suivi depuis la création de cette sauvegarde sera perdu. Cette action est irréversible.';

  @override
  String get restoreConfirmDescription =>
      'Cela fusionnera la sauvegarde cloud avec tes données locales. Les conflits seront résolus en utilisant les modifications les plus récentes.';

  @override
  String get restoreBackup => 'Restaurer';

  @override
  String get restore => 'Restaurer';

  @override
  String get backupHistory => 'Historique des sauvegardes';

  @override
  String get noBackupsFound => 'Aucune sauvegarde trouvée';

  @override
  String backupDateToday(Object time) {
    return 'Aujourd\'hui à $time';
  }

  @override
  String backupDateYesterday(Object time) {
    return 'Hier à $time';
  }

  @override
  String backupDateOther(Object month, Object day, Object time) {
    return '$day $month à $time';
  }

  @override
  String get monthJan => 'janv.';

  @override
  String get monthFeb => 'févr.';

  @override
  String get monthMar => 'mars';

  @override
  String get monthApr => 'avr.';

  @override
  String get monthMay => 'mai';

  @override
  String get monthJun => 'juin';

  @override
  String get monthJul => 'juil.';

  @override
  String get monthAug => 'août';

  @override
  String get monthSep => 'sept.';

  @override
  String get monthOct => 'oct.';

  @override
  String get monthNov => 'nov.';

  @override
  String get monthDec => 'déc.';

  @override
  String get migrationFailed =>
      'La migration a échoué. Vérifie ta phrase de passe.';

  @override
  String get pinProtection => 'Protection par code PIN';

  @override
  String get setPinTitle => 'Définir un code PIN';

  @override
  String get setPinDesc =>
      'Crée une phrase de passe ou un code PIN (au moins 4 caractères) pour mieux protéger ta clé de sauvegarde.';

  @override
  String get setLocalPinDesc =>
      'Ce code PIN servira à chiffrer tes sauvegardes locales. Sans lui, tes fichiers de sauvegarde ne pourront pas être déchiffrés.';

  @override
  String get disablePinTitle => 'Désactiver le code PIN';

  @override
  String get disablePinDesc =>
      'Saisis ton code PIN actuel pour retirer la protection par PIN.';

  @override
  String get unlockForSyncTitle => 'Déverrouiller la sauvegarde';

  @override
  String get unlockForSyncDesc =>
      'Saisis ton code PIN pour accéder à la sauvegarde pendant cette session.';

  @override
  String get pinHint => 'Phrase de passe ou PIN';

  @override
  String get pinTooShort => 'Doit comporter au moins 4 caractères';

  @override
  String get pinIncorrect => 'Phrase de passe ou PIN incorrect';

  @override
  String get unlockAction => 'Déverrouiller';

  @override
  String get disable => 'Désactiver';

  @override
  String get forgotPassphrase =>
      'Phrase de passe oubliée ? Supprimer l\'ancienne sauvegarde';

  @override
  String get discardOldBackupTitle => 'Supprimer l\'ancienne sauvegarde ?';

  @override
  String get discardOldBackupDesc =>
      'Ton ancienne sauvegarde chiffrée sera définitivement supprimée de Google Drive et remplacée par une nouvelle. Tes données locales actuelles sont en sécurité.';

  @override
  String get discardOldBackupConfirm => 'Supprimer';

  @override
  String get paywallUpgradeTo => 'Soutenir le projet';

  @override
  String get paywallSupportUs =>
      'Aide à garder Habitt gratuit en devenant supporter ou en faisant un don unique';

  @override
  String get paywallCustomScheduling =>
      'Planification personnalisée des habitudes';

  @override
  String get paywallPerHabitNotifications => 'Notifications par habitude';

  @override
  String get paywallImprovementSuggestions =>
      'Suggestions pour améliorer tes habitudes';

  @override
  String get paywallCloudBackupSync => 'Sauvegarde et synchronisation cloud';

  @override
  String get paywallBestValue => 'Meilleur rapport qualité-prix';

  @override
  String get paywallMostPopular => 'Le plus populaire';

  @override
  String get paywallUpgradeNow => 'Soutenir maintenant';

  @override
  String get paywallManageSubscription => 'Gérer mon soutien';

  @override
  String get paywallCancel => 'Arrêter de soutenir';

  @override
  String get paywallDowngrade => 'Soutenir moins';

  @override
  String get paywallUpgrade => 'Soutenir davantage';

  @override
  String get currentPlan => 'Formule actuelle';

  @override
  String renewsOn(String date) {
    return 'Se renouvelle le $date';
  }

  @override
  String get paywallYearly => 'Supporter annuel';

  @override
  String get paywallMonthly => 'Supporter mensuel';

  @override
  String get paywallLifetime => 'Supporter à vie';

  @override
  String get paywallSixMonths => 'Supporter 6 mois';

  @override
  String get paywallThreeMonths => 'Supporter 3 mois';

  @override
  String get paywallWeekly => 'Supporter hebdomadaire';

  @override
  String get paywallPerYear => '/ an';

  @override
  String get paywallPerMonth => '/ mois';

  @override
  String get paywallPerSixMonths => '/ 6 mois';

  @override
  String get paywallPerThreeMonths => '/ 3 mois';

  @override
  String get paywallPerWeek => '/ semaine';

  @override
  String get paywallOneTimePurchase => 'Achat unique';

  @override
  String get paywallProductsUnavailable =>
      'Impossible de charger les formules. Réessaie plus tard.';

  @override
  String get paywallRestorePurchases => 'Restaurer les achats';

  @override
  String get premadeSectionWellnessSelfCare =>
      'Bien-être / Prendre soin de soi';

  @override
  String get premadeSectionHealthFitness => 'Santé et forme';

  @override
  String get premadeSectionProductivityGrowth => 'Productivité et progression';

  @override
  String get premadeHabitGoToBedEarly => 'Se coucher tôt';

  @override
  String get premadeHabitBrushTeeth => 'Se brosser les dents';

  @override
  String get premadeHabitSkinCare => 'Soins de la peau';

  @override
  String get premadeHabitWakeUpEarly => 'Se lever tôt';

  @override
  String get premadeHabitShower => 'Douche';

  @override
  String get premadeHabitRunning => 'Course à pied';

  @override
  String get premadeHabitWalk => 'Marche';

  @override
  String get premadeHabitGym => 'Salle de sport';

  @override
  String get premadeHabitNutrition => 'Nutrition';

  @override
  String get premadeHabitMedications => 'Médicaments';

  @override
  String get premadeHabitDrinkWater => 'Boire de l\'eau';

  @override
  String get premadeHabitStudying => 'Étudier';

  @override
  String get premadeHabitWork => 'Travail';

  @override
  String get premadeHabitResearch => 'Recherche';

  @override
  String get premadeHabitRead => 'Lire';

  @override
  String get premadeHabitPraying => 'Prier';

  @override
  String get premadeHabitProductivitySession => 'Session de productivité';

  @override
  String get premadeSheetTitle => 'Choisir une habitude';

  @override
  String get premadeSheetDescCreate =>
      'Choisis une habitude dans les catégories, ou passe et crée la tienne';

  @override
  String get premadeSheetDescEdit =>
      'Les notifications, le style de l\'interface et les textes sont personnalisés selon l\'habitude choisie.';

  @override
  String get overrideCurrentConfigTitle =>
      'Remplacer la configuration actuelle ?';

  @override
  String get overrideCurrentConfigDesc =>
      'Remplacer les détails actuels de l\'habitude par le modèle, ou garder les options actuelles ?';

  @override
  String get overrideCurrentConfigOverride => 'Remplacer';

  @override
  String get overrideCurrentConfigKeepCurrent => 'Garder l\'actuel';

  @override
  String get apply => 'Appliquer';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get logOutDesc =>
      'Te déconnecter désactivera la sauvegarde et la synchronisation, mais tes données locales resteront sur cet appareil.';

  @override
  String get deleteAccountDesc =>
      'Supprime ton compte de nos serveurs. Les sauvegardes chiffrées dans le dossier habitt_backups de ton Google Drive resteront : supprime-les manuellement si besoin.';

  @override
  String get accountDeletedSuccessfully => 'Compte supprimé avec succès';

  @override
  String accountDeletionFailed(Object errorMessage) {
    return 'Échec de la suppression du compte : $errorMessage';
  }

  @override
  String get backupFound => 'Sauvegarde trouvée';

  @override
  String get backupFoundDesc =>
      'Ton Google Drive contient une sauvegarde. Comment veux-tu la restaurer ? La synchronisation ne démarrera pas avant que tu choisisses une option.';

  @override
  String get merge => 'Fusionner';

  @override
  String get overwriteLocalDataTitle => 'Écraser les données locales ?';

  @override
  String get overwriteLocalDataDesc =>
      'Cela remplacera définitivement toutes tes données locales par la sauvegarde. Cette action est irréversible.';

  @override
  String get overwrite => 'Écraser';

  @override
  String get syncSectionTitle => 'Synchronisation';

  @override
  String get syncSpeedTitle => 'Vitesse de synchronisation';

  @override
  String get syncSpeedFast => 'Rapide';

  @override
  String get syncSpeedOptimized => 'Optimisée';

  @override
  String get syncSpeedFastDescription =>
      'Synchronise après 5 s\nVérifie toutes les 30 s';

  @override
  String get syncSpeedFastHint =>
      'Les modifications sont envoyées après 5 secondes et tes données sont actualisées toutes les 30 secondes.';

  @override
  String get syncSpeedOptimizedDescription =>
      'Synchronise après 15 s\nVérifie toutes les 2 min';

  @override
  String get syncSpeedOptimizedHint =>
      'Les modifications sont regroupées et envoyées après une courte pause pour économiser la batterie.';

  @override
  String get disconnectGoogleDrive => 'Déconnecter Google Drive';

  @override
  String get connectGoogleDrive => 'Connecter Google Drive';

  @override
  String get pauseHabit => 'Mettre l\'habitude en pause';

  @override
  String pauseHabitName(Object name) {
    return 'Mettre « $name » en pause';
  }

  @override
  String get unpauseHabit => 'Reprendre l\'habitude';

  @override
  String get pauseHabitDesc =>
      'Pendant la pause, cette habitude n\'apparaîtra pas dans ta liste du jour. Ta série et tes statistiques seront conservées.';

  @override
  String get habitPaused => 'Habitude mise en pause !';

  @override
  String get habitUnpaused => 'Habitude reprise !';

  @override
  String get localBackups => 'Sauvegardes locales';

  @override
  String get localBackupsDesc =>
      'Exporte ou importe des fichiers de sauvegarde chiffrés sur cet appareil';

  @override
  String get exportBackup => 'Exporter la sauvegarde';

  @override
  String get exportBackupDesc =>
      'Enregistre un fichier de sauvegarde chiffré sur ton appareil';

  @override
  String get importBackup => 'Importer une sauvegarde';

  @override
  String get importBackupDesc =>
      'Restaure à partir d\'un fichier de sauvegarde chiffré';

  @override
  String get exportSuccess => 'Sauvegarde exportée avec succès.';

  @override
  String get exportFailed => 'Échec de l\'export. Réessaie.';

  @override
  String get importSuccess => 'Sauvegarde importée avec succès.';

  @override
  String get importFailed => 'Échec de l\'import. Réessaie.';

  @override
  String get setPin => 'Définir le PIN';

  @override
  String get pinEnabled => 'PIN activé';

  @override
  String get changePin => 'Modifier le PIN';

  @override
  String get removePin => 'Supprimer le PIN';

  @override
  String get revealPin => 'Afficher le PIN';

  @override
  String get confirmPin => 'Confirmer le PIN';

  @override
  String get currentPin => 'PIN actuel';

  @override
  String get newPin => 'Nouveau PIN';

  @override
  String get confirmNewPin => 'Confirmer le nouveau PIN';

  @override
  String get pinMismatch => 'Les PIN ne correspondent pas';

  @override
  String get pinChangedSuccess => 'PIN modifié';

  @override
  String get pinRemovedSuccess => 'PIN supprimé';

  @override
  String get pinSetSuccess => 'PIN défini';

  @override
  String get pinCopied => 'PIN copié';

  @override
  String get exportUnencryptedWarningTitle => 'Exporter sans chiffrement ?';

  @override
  String get exportUnencryptedWarningDesc =>
      'Aucun PIN n\'est défini. Ce fichier de sauvegarde ne sera pas chiffré. Toute personne qui y a accès pourra lire tes données.';

  @override
  String get exportUnencryptedConfirm => 'Exporter quand même';

  @override
  String get enterPinToDecrypt => 'Saisis le PIN de la sauvegarde';

  @override
  String get wrongPin => 'PIN incorrect. Réessaie.';

  @override
  String get importSuccessPinSaved =>
      'Sauvegarde importée. PIN enregistré pour les prochaines sauvegardes.';

  @override
  String get useThisPinQuestion =>
      'Utiliser ce PIN pour les prochaines sauvegardes ?';

  @override
  String get savePin => 'Enregistrer le PIN';

  @override
  String get removePinDesc =>
      'Les prochaines sauvegardes ne seront pas chiffrées. Toute personne qui y a accès pourra lire tes données.';

  @override
  String get connectICloud => 'Connecter iCloud';

  @override
  String get disconnectICloud => 'Déconnecter iCloud';

  @override
  String get syncFailedDrive => 'Échec de la synchronisation Google Drive';

  @override
  String get syncFailedICloud => 'iCloud indisponible : vérifie les Réglages';

  @override
  String get syncFailedICloudQuota => 'Espace iCloud insuffisant';

  @override
  String get syncWarningICloudQuota =>
      'Espace Apple plein : données enregistrées uniquement en local';

  @override
  String get syncFailedDriveQuota => 'Espace Google Drive plein';

  @override
  String get singular => 'Singulier';

  @override
  String get singularHint => 'ex. verre';

  @override
  String get plural => 'Pluriel';

  @override
  String get pluralHint => 'ex. verres';

  @override
  String get habitNames => 'Noms des habitudes';

  @override
  String get habitNamesDesc =>
      'Définis un nom personnalisé pour chaque langue. Quand tu changes la langue de l\'app, le nom correspondant s\'affichera automatiquement.';

  @override
  String get autoAssignHabitNames => 'Attribution automatique des noms';

  @override
  String get autoAssignHabitNamesDesc =>
      'Enregistre automatiquement le nom de ton habitude pour la langue actuelle à chaque sauvegarde.';

  @override
  String get holdToCompleteTipTitle => 'Maintenir pour terminer';

  @override
  String get holdToCompleteTipBody =>
      'Maintiens la coche enfoncée pour valider immédiatement ton objectif complet.';

  @override
  String get syncOverlayTitleSyncing => 'Synchronisation';

  @override
  String get syncOverlayTitleUploading => 'Envoi';

  @override
  String get syncOverlayTitleUpToDate => 'À jour';

  @override
  String syncOverlayUpdatesRemaining(int count) {
    return '$count mises à jour restantes...';
  }

  @override
  String get syncOverlayDownloadingBackup =>
      'Téléchargement de la sauvegarde...';

  @override
  String get syncOverlayUploadingChanges =>
      'Envoi des modifications récentes vers le cloud...';

  @override
  String get showUploadActivity => 'Afficher l\'activité d\'envoi';

  @override
  String get showUploadActivityDesc =>
      'Lorsque c\'est activé, un écran de synchronisation s\'affiche pendant l\'envoi des modifications vers le cloud. Désactive-le pour envoyer en silence en arrière-plan.';

  @override
  String get syncOverlayTitleOptimizing => 'Optimisation';

  @override
  String syncOverlayOptimizingRemaining(int count) {
    return '$count fichiers restants...';
  }

  @override
  String get followHabitSchedule => 'Suivre le planning de l\'habitude';

  @override
  String get notificationScheduleDependencyTip =>
      'Ce rappel ne se déclenche que les jours où l\'habitude est prévue.';

  @override
  String get notificationWeekdaysFixedTip =>
      'L\'habitude n\'apparaîtra jamais les jours désactivés. Pour modifier cela, change tes options de planification hebdomadaire.';

  @override
  String get importHabitKitDesc =>
      'Tes habitudes et ton historique seront importés.';

  @override
  String importHabitKitMergeDesc(String appName) {
    return 'Garde tes habitudes et ajoute celles de $appName. Les habitudes portant le même nom seront fusionnées.';
  }

  @override
  String importHabitKitReplaceDesc(Object appName) {
    return 'Supprime d\'abord tes habitudes actuelles, puis importe celles de $appName. Cette action est irréversible.';
  }

  @override
  String get importHabitKitNote =>
      'Les icônes et couleurs peuvent changer. Les « mauvaises habitudes » sont importées comme des habitudes classiques';

  @override
  String get replace => 'Remplacer';

  @override
  String get importFromOtherApps => 'Importer depuis d\'autres apps';

  @override
  String importHabitKitTitle(String appName) {
    return 'Importer les données de $appName';
  }

  @override
  String get backupBeforeImporting =>
      'Il est vivement conseillé de sauvegarder tes données avant de continuer.';

  @override
  String get streakCelebration => 'Célébration de série';

  @override
  String get streakCelebrationDesc =>
      'Affiche une célébration quand ta série de jours parfaits progresse.';

  @override
  String get completionSound => 'Son de validation';

  @override
  String get completionSoundDesc =>
      'Joue un court son quand tu termines une habitude.';

  @override
  String get greatProgress => 'Excellent progrès';

  @override
  String get buildingRealConsistency => 'Tu construis une vraie régularité';

  @override
  String get keepGoing => 'Continue !';

  @override
  String get goodJob => 'Bien joué !';

  @override
  String get bravo => 'Bravo !';

  @override
  String get keepItUp => 'Continue comme ça !';

  @override
  String get youreALegend => 'Tu es une légende !';

  @override
  String get streakInventYou =>
      'Si tu n\'existais pas, il faudrait t\'inventer !';

  @override
  String get streakPraiseExtra1 => 'C\'est ça, champion !';

  @override
  String get streakPraiseExtra2 => 'Bien joué, toi !';

  @override
  String get streakPraiseExtra3 => 'Chapeau !';

  @override
  String get backAtIt => 'C\'est reparti';

  @override
  String get timeForHabits => 'C\'est l\'heure des habitudes ?';

  @override
  String get notificationDismissAction => 'Ignorer';

  @override
  String get notificationCompleteAction => 'Terminer';

  @override
  String get notificationSoundSettingTitle => 'Son de notification';

  @override
  String get notificationSoundSettingSubtitle => 'Son joué pour les rappels';

  @override
  String get habitSoundTitle => 'Son du rappel';

  @override
  String get habitAlarmTitle => 'Alarme';

  @override
  String get habitAlarmSubtitle =>
      'Sonne jusqu\'à ce que tu la désactives. Idéal pour les habitudes urgentes comme la prise de médicaments.';

  @override
  String get useGlobalDefaultSound => 'Utiliser le son par défaut';

  @override
  String soundNumbered(int number) {
    return 'Son $number';
  }

  @override
  String get notificationSoundAppDefault => 'Par défaut de l\'app';

  @override
  String get notificationSoundSystemDefault => 'Système';

  @override
  String get optional => 'Facultatif';

  @override
  String get becomeASupporter => 'Devenir supporter';

  @override
  String get or => 'ou';

  @override
  String get buyMeACoffee => 'Offre-moi un café';

  @override
  String get makeOneTimeDonationOfAnyAmount =>
      'Fais un don unique, du montant de ton choix';

  @override
  String get donate => 'Faire un don';

  @override
  String get everyDonationHelpsSupportFutureUpdates =>
      'Chaque don aide à financer les futures mises à jour';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get showCategoriesOnMainPage => 'Catégories d\'habitudes';

  @override
  String get showCategoriesOnMainPageDesc =>
      'Un filtre par catégorie apparaîtra au-dessus de tes habitudes sur l\'écran d\'accueil.';

  @override
  String get outdatedDeviceTitle => 'Mets à jour ton autre appareil';

  @override
  String get outdatedDeviceMessage =>
      'Un autre appareil de ton compte utilise une ancienne version de Habitt. Mets-la à jour vers la dernière version pour assurer une synchronisation correcte.';

  @override
  String get gotIt => 'Compris';

  @override
  String get timerDialogTitle => 'Démarrer un minuteur';

  @override
  String get timerCloseHint =>
      'Tu peux fermer cet écran. Le minuteur continuera de tourner';

  @override
  String get timerInProgress => 'En cours...';

  @override
  String get timerPaused => 'En pause';

  @override
  String get completeHabit => 'Terminer l\'habitude';

  @override
  String get timerPauseToEditHint =>
      'Mets le minuteur en pause pour modifier la progression manuellement';

  @override
  String get timerAlreadyRunningTitle => 'Un minuteur est déjà en cours';

  @override
  String timerSwitchDesc(String name) {
    return 'Arrêter le minuteur actuel et en démarrer un pour « $name » à la place ?';
  }

  @override
  String get timerStopAndStart => 'Arrêter et démarrer';

  @override
  String get habitPausedDesc =>
      'Cette habitude est actuellement en pause. Pour ajouter de la progression, tu dois d\'abord la reprendre.';

  @override
  String get habitDeletedDesc =>
      'Cette habitude a été supprimée. Pour ajouter de la progression, tu dois d\'abord la restaurer.';

  @override
  String get deleted => 'Supprimées';

  @override
  String get noDeletedHabits => 'Aucune habitude supprimée';

  @override
  String get deletedHabits => 'Habitudes supprimées';

  @override
  String get unpause => 'Reprendre';

  @override
  String get habitRestored => 'Habitude restaurée !';

  @override
  String get later => 'Plus tard';

  @override
  String get consistencyMessage =>
      'Tu as manqué de régularité ces derniers temps. Reprends le rythme !';

  @override
  String get current => 'Actuel';

  @override
  String get suggested => 'Suggéré';

  @override
  String get needed => 'Nécessaire';

  @override
  String get streakFadingNudge1 => 'Ne te laisse pas tomber';

  @override
  String get streakFadingNudge2 => 'Ta série est en train de se perdre';

  @override
  String get streakFadingNudge3 => 'Il est temps de reprendre le rythme';

  @override
  String get streakFadingPartial1 => 'Bon début, termine maintenant';

  @override
  String get streakFadingPartial2 => 'Presque fini, termine-la';

  @override
  String get streakCriticalWarning1 => 'Dernière chance de sauver ta série !';

  @override
  String get streakCriticalWarning2 => 'Ne rate pas aujourd\'hui !';

  @override
  String get streakCriticalPartial1 =>
      'Termine aujourd\'hui pour faire grandir ta série';

  @override
  String get streakCriticalPartial2 =>
      'Tu y es presque, termine et elle grandira';

  @override
  String get deletedToday => 'Aujourd\'hui';

  @override
  String get deletedOneDayAgo => 'Il y a 1 jour';

  @override
  String deletedDaysAgoLabel(Object days) {
    return 'Il y a $days jours';
  }

  @override
  String get deletedHabitsPageDesc =>
      'Les habitudes supprimées restent ici pendant 30 jours, puis sont définitivement retirées.';

  @override
  String get restoreDeletedHabitConfirm =>
      'Restaurer cette habitude ? Sa série tiendra compte des jours manqués pendant la suppression.';

  @override
  String get healthSyncSectionTitleApple => 'Synchroniser avec Apple Santé';

  @override
  String get healthSyncSectionTitleAndroid =>
      'Synchroniser avec Health Connect';

  @override
  String get healthSyncSectionDescApple =>
      'Met automatiquement à jour la progression de cette habitude depuis Apple Santé';

  @override
  String get healthSyncSectionDescAndroid =>
      'Met automatiquement à jour la progression de cette habitude depuis Health Connect';

  @override
  String get healthMetricSteps => 'Pas';

  @override
  String get healthMetricSleep => 'Sommeil';

  @override
  String get healthMetricExerciseMinutes => 'Entraînement';

  @override
  String get healthMetricMindfulMinutes => 'Pleine conscience';

  @override
  String get healthMetricActivity => 'Activité';

  @override
  String get healthMetricActiveCalories => 'Calories actives';

  @override
  String get healthMetricTotalCalories => 'Calories totales';

  @override
  String get healthPermissionDeniedMessage =>
      'Habitt n\'a pas l\'autorisation de lire ces données. Tu peux activer l\'accès dans les Réglages.';

  @override
  String get calorie => 'calorie';

  @override
  String get calories => 'calories';

  @override
  String get premadeSectionWorkouts => 'Entraînements';

  @override
  String get premadeHabitWorkoutWalking => 'Marche';

  @override
  String get premadeHabitWorkoutRunning => 'Course';

  @override
  String get premadeHabitWorkoutCycling => 'Vélo';

  @override
  String get premadeHabitWorkoutSwimming => 'Natation';

  @override
  String get premadeHabitWorkoutHiking => 'Randonnée';

  @override
  String get premadeHabitWorkoutFlexibility => 'Étirements';

  @override
  String get premadeHabitWorkoutDancing => 'Danse';

  @override
  String get premadeHabitWorkoutRowing => 'Aviron';

  @override
  String get premadeHabitWorkoutCombined => 'Entraînement';

  @override
  String get healthConnectedStatusApple => 'Connecté à Apple Santé';

  @override
  String get healthConnectedStatusAndroid => 'Connecté à Health Connect';

  @override
  String get healthTrackByDuration => 'Durée';

  @override
  String get healthTrackByCount => 'Nombre';

  @override
  String get healthTargetBedtime => 'Heure de coucher visée';

  @override
  String get healthTargetWakeTime => 'Heure de réveil visée';

  @override
  String get healthToleranceLoose => 'Souple';

  @override
  String get healthToleranceRegular => 'Standard';

  @override
  String get healthToleranceStrict => 'Stricte';

  @override
  String get healthLastNight => 'La nuit dernière';

  @override
  String get healthMetricPickerTitle => 'Quoi synchroniser ?';

  @override
  String get premadeRequestHabitPrompt => 'Tu ne vois pas ton habitude ?';

  @override
  String get premadeRequestHabitLink => 'Propose-en une';

  @override
  String get habitRequestEmailSubject => 'Demande d\'habitude';

  @override
  String healthToleranceMinutesValue(Object minutes) {
    return '$minutes minutes';
  }

  @override
  String get healthToleranceHourValue => '1 heure';

  @override
  String healthToleranceDescBedtime(Object duration) {
    return 'Te coucher plus tôt que ton objectif est toujours bien. Tu peux aussi aller jusqu\'à $duration plus tard et ça compte quand même';
  }

  @override
  String healthToleranceDescWakeTime(Object duration) {
    return 'Te réveiller plus tôt que ton objectif est toujours bien. Tu peux aussi te réveiller jusqu\'à $duration plus tard et ça compte quand même';
  }

  @override
  String healthToleranceDescSleep(Object duration) {
    return 'Dormir plus que ton objectif est toujours bien. Tu peux aussi dormir jusqu\'à $duration de moins et ça compte quand même';
  }

  @override
  String get healthMetricDescSteps => 'Suit tes pas';

  @override
  String get healthMetricDescSleep => 'Suit ton temps de sommeil';

  @override
  String get healthMetricDescWorkouts => 'Suit tous tes entraînements';

  @override
  String get healthMetricDescMindfulness =>
      'Suit tes séances de pleine conscience';

  @override
  String get healthMetricDescActivity =>
      'Suit ton anneau d\'exercice de l\'Apple Watch';

  @override
  String get healthMetricDescActiveCalories =>
      'Suit les calories actives que tu brûles';

  @override
  String get healthMetricDescTotalCalories =>
      'Suit le total des calories que tu brûles';

  @override
  String get healthMetricDescBedtime => 'Suit à quelle heure tu t\'es couché';

  @override
  String get healthMetricDescWakeTime =>
      'Suit à quelle heure tu t\'es réveillé';

  @override
  String get premadeHabitMindfulness => 'Pleine conscience';

  @override
  String get premadeHabitActivity => 'Activité';

  @override
  String get premadeHabitSleepTime => 'Temps de sommeil';

  @override
  String get premadeHabitActiveCalories => 'Calories actives';

  @override
  String get premadeHabitTotalCalories => 'Calories totales';

  @override
  String get healthWorkoutTypePickerTitle => 'Choisis un type d\'entraînement';

  @override
  String get healthWorkoutFilterAny => 'Tous';

  @override
  String get healthWorkoutLabelAnySingular => 'entraînement';

  @override
  String get healthWorkoutLabelAnyPlural => 'entraînements';

  @override
  String get healthWorkoutLabelOtherSingular => 'entraînement';

  @override
  String get healthWorkoutLabelOtherPlural => 'entraînements';

  @override
  String get healthWorkoutLabelWalkingSingular => 'marche';

  @override
  String get healthWorkoutLabelWalkingPlural => 'marches';

  @override
  String get healthWorkoutLabelRunningSingular => 'course';

  @override
  String get healthWorkoutLabelRunningPlural => 'courses';

  @override
  String get healthWorkoutLabelCyclingSingular => 'sortie à vélo';

  @override
  String get healthWorkoutLabelCyclingPlural => 'sorties à vélo';

  @override
  String get healthWorkoutLabelSwimmingSingular => 'séance de natation';

  @override
  String get healthWorkoutLabelSwimmingPlural => 'séances de natation';

  @override
  String get healthWorkoutLabelHikingSingular => 'randonnée';

  @override
  String get healthWorkoutLabelHikingPlural => 'randonnées';

  @override
  String get healthWorkoutLabelFlexibilitySingular => 'séance';

  @override
  String get healthWorkoutLabelFlexibilityPlural => 'séances';

  @override
  String get healthWorkoutLabelDancingSingular => 'danse';

  @override
  String get healthWorkoutLabelDancingPlural => 'danses';

  @override
  String get healthWorkoutLabelRowingSingular => 'sortie d\'aviron';

  @override
  String get healthWorkoutLabelRowingPlural => 'sorties d\'aviron';

  @override
  String get healthMindfulnessLabelSingular => 'séance';

  @override
  String get healthMindfulnessLabelPlural => 'séances';

  @override
  String get overrideFieldsDialogTitle => 'Choisis ce qui doit être mis à jour';

  @override
  String get overrideFieldsDialogDesc =>
      'Choisis les éléments de ton habitude à mettre à jour selon ce modèle. Ce qui n\'est pas coché garde sa valeur actuelle.';

  @override
  String get overrideFieldsSelectAll => 'Tout sélectionner';

  @override
  String get overrideFieldsDeselectAll => 'Tout désélectionner';

  @override
  String get overrideFieldName => 'Nom';

  @override
  String get overrideFieldIcon => 'Icône';

  @override
  String get overrideFieldCategory => 'Catégorie';

  @override
  String get overrideFieldTarget => 'Objectif';

  @override
  String get overrideFieldHealthSync => 'Synchro santé';

  @override
  String get overrideFieldSchedule => 'Planning';

  @override
  String get overrideFieldNotifications => 'Notifications';

  @override
  String get timerCompletedNotificationTitle => 'Objectif atteint';

  @override
  String timerCompletedNotificationBody(String name) {
    return '\'$name\' a atteint son objectif.';
  }

  @override
  String get healthBedtimeDayTitle => 'Compter le coucher pour';

  @override
  String get healthBedtimeDayWake => 'Jour du réveil';

  @override
  String get healthBedtimeDayBefore => 'Veille';

  @override
  String get healthBedtimeDayWakeDesc =>
      'Ton coucher compte le jour où tu te réveilles. Te coucher le lundi soir compte pour le mardi';

  @override
  String get healthBedtimeDayBeforeDesc =>
      'Ton coucher compte la veille de ton réveil. Te coucher le lundi soir compte pour le lundi';

  @override
  String get healthCardNotSyncedYet => 'Pas encore synchronisé';

  @override
  String get healthCardSyncing => 'Synchronisation…';

  @override
  String get healthCardPermissionNeeded =>
      'Autorise l\'accès pour continuer la synchro';

  @override
  String get healthCardLast7Days => '7 derniers jours';

  @override
  String get healthCardNoData =>
      'Aucune donnée Santé pour ces jours pour le moment';

  @override
  String get healthCardSessions => 'Séances';

  @override
  String get healthCardNoSessions => 'Aucune séance enregistrée pour ce jour';

  @override
  String notificationSleepHours(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String notificationSleepMinutes(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String notificationSleepHoursAndMinutes(Object hours, Object minutes) {
    return '$hours et $minutes';
  }

  @override
  String notificationSleepBedtimeSoon(Object countdown, Object time) {
    return 'Prépare-toi à dormir, ton coucher est dans $countdown.|Il est temps de ralentir, ton coucher est dans $countdown.|Commence ta routine du soir, extinction des lumières dans $countdown.|Presque l\'heure du coucher ! Plus que $countdown avant $time.';
  }

  @override
  String notificationSleepBedtime(Object time) {
    return 'Juste un rappel pour te coucher tôt ce soir.|Ton objectif de coucher est $time. Commence à ralentir.|Une soirée tôt ce soir rend demain plus facile.|Range ton téléphone bientôt, ton coucher est à $time.';
  }

  @override
  String notificationSleepWakeUp(Object time) {
    return 'Bonjour ! Ton objectif de réveil est $time.|Il est temps de te lever, ton objectif est $time. Tu peux le faire !|Debout, un début de journée calme et tôt en vaut la peine.|Juste un rappel pour te réveiller tôt, ton objectif est $time.';
  }

  @override
  String notificationSleepGoal(Object goal) {
    return 'Vise $goal de sommeil ce soir.|Va au lit à l\'heure pour atteindre tes $goal de sommeil ce soir.|Ton objectif ce soir : $goal de sommeil. Commence à ralentir.|Protège ton sommeil ce soir, $goal est la cible.';
  }

  @override
  String notificationSleepGoalProgress(Object goal, Object slept) {
    return 'Tu as dormi $slept sur ton objectif de $goal. Vise une nuit plus tôt ce soir.|Tu es à $slept sur $goal de sommeil. Fais de cette nuit une réussite.';
  }

  @override
  String notificationHealthStepsStart(Object goal) {
    return 'Il est temps de bouger, ton objectif est $goal aujourd\'hui.|Une marche maintenant te rapproche de $goal.|Chaque pas compte, vise $goal aujourd\'hui.|Étire tes jambes, $goal t\'attend.';
  }

  @override
  String notificationHealthStepsProgress(Object progress, Object remaining) {
    return 'Tu es à $progress. Plus que $remaining !|Il reste $remaining pour atteindre ton objectif, continue de marcher.|Beau progrès, $progress jusqu\'ici. Une courte marche suffit à finir.';
  }

  @override
  String notificationHealthActiveCaloriesStart(Object goal) {
    return 'Mets ton corps en mouvement, l\'objectif du jour est $goal brûlées.|Un entraînement ou une marche rapide te mène à $goal.|C\'est l\'heure de brûler de l\'énergie, ton objectif est $goal.|Bouge un peu maintenant, la cible du jour est $goal.';
  }

  @override
  String notificationHealthActiveCaloriesProgress(
    Object progress,
    Object remaining,
  ) {
    return 'Tu as déjà brûlé $progress. Plus que $remaining !|Il reste $remaining pour atteindre ton objectif, continue de bouger.|Excellent travail, $progress brûlées. Finis en beauté !';
  }

  @override
  String notificationHealthTotalCaloriesStart(Object goal) {
    return 'Ton objectif total de calories pour aujourd\'hui est $goal. Reste en mouvement !|Bouge aujourd\'hui, la cible totale est $goal.|Objectif énergétique total du jour : $goal. Un peu de mouvement aide.';
  }

  @override
  String notificationHealthTotalCaloriesProgress(
    Object progress,
    Object remaining,
  ) {
    return 'Tu as atteint $progress aujourd\'hui, il reste $remaining.|Il reste $remaining pour atteindre l\'objectif calorique du jour.|Bon rythme, $progress jusqu\'ici. Continue comme ça !';
  }

  @override
  String notificationHealthMindfulnessStart(Object goal) {
    return 'Prends $goal pour respirer et te recentrer.|Une courte pause de pleine conscience de $goal est tout ce dont tu as besoin.|Fais une pause de $goal de pleine conscience aujourd\'hui.|Ton esprit mérite $goal de calme.';
  }

  @override
  String notificationHealthMindfulnessProgress(
    Object progress,
    Object remaining,
  ) {
    return '$progress de pleine conscience jusqu\'ici. Encore $remaining pour atteindre ton objectif.|Il reste $remaining de calme pour atteindre ton objectif.';
  }

  @override
  String notificationHealthActivityStart(Object goal) {
    return 'Fais $goal d\'activité aujourd\'hui. Une marche rapide compte.|Vise $goal d\'exercice aujourd\'hui, chaque mouvement compte.|C\'est l\'heure de bouger, ton objectif d\'activité est $goal.|Continue de bouger, l\'objectif du jour est $goal d\'activité.';
  }

  @override
  String notificationHealthActivityProgress(Object progress, Object remaining) {
    return '$progress d\'activité jusqu\'ici. Encore $remaining pour atteindre ton objectif.|Il reste $remaining d\'activité, continue de bouger !|Super, $progress d\'activité aujourd\'hui. Plus que $remaining.';
  }

  @override
  String notificationHealthWorkoutStart(Object activity, Object goal) {
    return '$activity : ton objectif du jour est $goal.|$activity est prévu aujourd\'hui, vise $goal.|Objectif $activity du jour : $goal. C\'est parti !|C\'est l\'heure de $activity ! Ton objectif est $goal.';
  }

  @override
  String notificationHealthWorkoutProgress(
    Object activity,
    Object progress,
    Object remaining,
  ) {
    return '$activity : tu es à $progress, plus que $remaining !|Progression $activity : $progress. Continue, il reste $remaining.|$activity : plus que $remaining pour atteindre ton objectif.';
  }

  @override
  String get notificationHealthNudgeWalking =>
      'C\'est l\'heure de lacer tes chaussures et de sortir marcher.|L\'air frais et une marche te feront du bien.';

  @override
  String get notificationHealthNudgeRunning =>
      'Lace tes chaussures, c\'est l\'heure de courir.|C\'est le moment de sortir courir.';

  @override
  String get notificationHealthNudgeCycling =>
      'Prends ton vélo, c\'est l\'heure de rouler.|C\'est le moment de monter sur ton vélo.';

  @override
  String get notificationHealthNudgeSwimming =>
      'C\'est l\'heure d\'aller à la piscine.|Prends ton maillot, une séance de natation t\'attend.';

  @override
  String get notificationHealthNudgeHiking =>
      'Les sentiers t\'appellent, c\'est l\'heure de randonner.|C\'est le moment de prendre le sentier.';

  @override
  String get notificationHealthNudgeFlexibility =>
      'Prends un moment pour t\'étirer et te détendre.|C\'est l\'heure de t\'étirer.';

  @override
  String get notificationHealthNudgeDancing =>
      'Mets de la musique et danse.|C\'est l\'heure de danser au rythme de la musique.';

  @override
  String get notificationHealthNudgeRowing =>
      'C\'est l\'heure de ramer.|Prends les avirons, une séance d\'aviron t\'attend.';

  @override
  String get healthEditedManually => 'Modifié manuellement';

  @override
  String healthUseSourceValues(Object source) {
    return 'Utiliser les valeurs de $source';
  }

  @override
  String healthOverrideNoticeTitle(Object source) {
    return '$source est en pause pour ce jour';
  }

  @override
  String healthOverrideNoticeBody(Object source) {
    return 'Tu as modifié cette progression toi-même, donc Habitt ne la remplacera pas par les données de $source pour ce jour. Ton chiffre reste exactement tel que tu l\'as saisi.\n\nTu veux récupérer $source ? Appuie sur \"Utiliser les valeurs de $source\" sur cette habitude.';
  }

  @override
  String get healthOverrideNoticeUnderstood => 'Compris';

  @override
  String premadeHealthSyncTitle(Object source) {
    return 'Synchroniser avec $source ?';
  }

  @override
  String premadeHealthSyncDesc(Object source) {
    return 'Habitt peut lire $source pour synchroniser tes données et valider cette habitude à ta place.';
  }

  @override
  String premadeHealthSyncAccept(Object source) {
    return 'Utiliser $source';
  }

  @override
  String get premadeHealthSyncDecline => 'Suivre manuellement';

  @override
  String healthNoRecentDataHintIos(Object source) {
    return 'Aucune donnée $source depuis quelques jours. Si tu n\'as pas autorisé Habitt à accéder aux données, ouvre Réglages → Santé → Accès aux données et appareils → Habitt et active les données dont il a besoin.';
  }

  @override
  String get healthOpenSettings => 'Ouvrir les réglages';

  @override
  String premadeHealthSettingDesc(Object source) {
    return 'Indique si $source est activé automatiquement pour les nouvelles habitudes qui le prennent en charge.';
  }

  @override
  String healthAccessLostMessage(Object source) {
    return 'La synchronisation avec $source ne fonctionne plus car Habitt n\'a pas l\'autorisation. Tes habitudes Santé ne seront pas mises à jour tant que tu n\'auras pas autorisé l\'accès dans les réglages.';
  }

  @override
  String get separateOptionalHabits => 'Séparer les habitudes facultatives';

  @override
  String get separateOptionalHabitsDesc =>
      'Les habitudes facultatives sortent de leurs catégories pour rejoindre leur propre section en bas, que tu peux replier.';

  @override
  String get strengthOverTime => 'Force au fil du temps';

  @override
  String get strengthChartNotEnoughData =>
      'Continue. Ta courbe de progression apparaîtra après quelques jours.';

  @override
  String get habitAgeStartedToday => 'Commencée aujourd\'hui, bonne chance !';

  @override
  String get statsRange7Days => '7J';

  @override
  String get statsRange30Days => '30J';

  @override
  String get statsRangeAll => 'TOUT';

  @override
  String get noHabitsScheduledToday =>
      'Aucune habitude prévue pour aujourd\'hui';

  @override
  String get noHabitsScheduledDay => 'Aucune habitude prévue pour ce jour';

  @override
  String get noTimedHabitsToday =>
      'Aucune habitude d\'aujourd\'hui n\'a de créneau horaire';

  @override
  String get noTimedHabitsDay =>
      'Aucune habitude de ce jour n\'a de créneau horaire';

  @override
  String get habitAgeCardTitle => 'Tu fais ça depuis';

  @override
  String get habitAgeCardNew => 'Tout juste commencé';

  @override
  String habitAgeCardYearsMonthsDays(Object years, Object months, Object days) {
    return '$years a $months m $days j';
  }

  @override
  String get habitAgeMilestoneStarting => 'Tu viens de commencer';

  @override
  String get habitAgeMilestoneRhythm => 'Tu trouves ton rythme';

  @override
  String get habitAgeMilestoneRoutine => 'Ça devient une routine';

  @override
  String get habitAgeMilestoneImpressive => 'Impressionnant !';

  @override
  String get habitAgeMilestoneOutstanding => 'Remarquable !';

  @override
  String get habitAgeMilestoneDedication =>
      'Une année entière. Quel dévouement !';

  @override
  String get habitAgeMilestoneLegendary => 'Une régularité légendaire !';

  @override
  String get back => 'Retour';

  @override
  String get setDaySchedule => 'Définir le planning du jour';

  @override
  String get daySchedule => 'Planning du jour';

  @override
  String get daySchedulePrompt =>
      'Indique quand cette habitude doit avoir lieu dans la journée';

  @override
  String get noFixedTime => 'Pas d\'heure fixe';

  @override
  String habitAppearsInSection(String section) {
    return 'L\'habitude apparaît dans la section $section';
  }

  @override
  String get specificTime => 'Heure précise';

  @override
  String get specificTimeDesc => 'Planifier à une heure précise';

  @override
  String get timeRange => 'Plage horaire';

  @override
  String get timeRangeDesc => 'Planifier avec une heure de début et de fin';

  @override
  String get setStartTime => 'Définir l\'heure de début';

  @override
  String get setEndTime => 'Définir l\'heure de fin';

  @override
  String get setTimeRange => 'Définir la plage horaire';

  @override
  String get startTimeLabel => 'Début :';

  @override
  String get endTimeLabel => 'Fin :';

  @override
  String get startsAt => 'Commence à :';

  @override
  String get endsAt => 'Se termine à :';

  @override
  String get timeRangeSameTimes =>
      'L\'heure de début et de fin ne peuvent pas être identiques';

  @override
  String get showIfMissed => 'Réafficher si manquée';

  @override
  String get showIfMissedDesc =>
      'Si tu rates un jour prévu, continue d\'afficher cette habitude chaque jour jusqu\'à ce que tu la valides, puis répète l\'intervalle à partir de ce jour';

  @override
  String get supportBannerText =>
      'Habitt n\'a ni publicité ni paywall. Aide à le garder ainsi en faisant un don.';

  @override
  String get supportSeeWays => 'Voir comment soutenir';

  @override
  String get supportAlreadyDonated => 'J\'ai déjà fait un don';

  @override
  String get supportBannerDismiss => 'Ignorer';

  @override
  String get supporterThankYouTitle => 'Merci de soutenir Habitt';

  @override
  String get supporterThankYouDesc =>
      'Tu aides à le garder sans publicité ni paywall pour tout le monde.';

  @override
  String get supportMilestoneText =>
      'Habitt n\'a ni publicité ni paywall. Si tu l\'apprécies, pense à le soutenir.';

  @override
  String get themeSettingTitle => 'Thème';

  @override
  String get themeNameHabitt => 'Habitt';

  @override
  String get themeNameLagoon => 'Lagune';

  @override
  String get themeNameOcean => 'Océan';

  @override
  String get themeNameIndigo => 'Indigo';

  @override
  String get themeNameViolet => 'Violet';

  @override
  String get themeNameOrchid => 'Orchidée';

  @override
  String get supportSheetTitle => 'Gratuit pour tous';

  @override
  String get supportSheetDesc =>
      'Les thèmes et la sauvegarde cloud sont gratuits pour tout le monde. Les donateurs aident Habitt à continuer.';

  @override
  String get supportNotNow => 'Pas maintenant';

  @override
  String get supportHabittRow => 'Soutenir Habitt';

  @override
  String get notificationsOffInSystemTitle =>
      'Les notifications sont désactivées';

  @override
  String get notificationsOffInSystemDesc =>
      'Habitt ne peut pas envoyer de rappels car les notifications sont désactivées pour lui dans les réglages de ton appareil.';

  @override
  String get openSettings => 'Ouvrir les réglages';

  @override
  String get pausedTag => 'En pause';

  @override
  String get tomorrow => 'Demain';

  @override
  String dayMonthLabel(String day, String daySuffix, String month) {
    return '$day$daySuffix $month';
  }

  @override
  String dayMonthYearLabel(
    String day,
    String daySuffix,
    String month,
    String year,
  ) {
    return '$day$daySuffix $month $year';
  }

  @override
  String get nextScheduledTitle => 'Prochaine échéance';

  @override
  String get nextResetTitle => 'Prochaine réinitialisation';

  @override
  String dateWithTimeLabel(String date, String time) {
    return '$date, $time';
  }

  @override
  String get weeklyResetInfo =>
      'La progression hebdomadaire se réinitialise chaque lundi.\nTon objectif global et ta série ne seront pas affectés.';

  @override
  String get monthlyResetInfo =>
      'La progression mensuelle se réinitialise le 1er de chaque mois.\nTon objectif global et ta série ne seront pas affectés.';

  @override
  String get ok => 'OK';

  @override
  String get whatsNewTitle => 'Nouveautés de la 2.5.0';

  @override
  String get whatsNewHealthTitle => 'Synchro santé';

  @override
  String get whatsNewHealthDesc =>
      'Relie une habitude aux pas, au sommeil, aux entraînements, aux minutes de pleine conscience ou aux calories, et Habitt met à jour ta progression automatiquement.';

  @override
  String get whatsNewAlarmsTitle => 'Alarmes d\'habitudes';

  @override
  String get whatsNewAlarmsDesc =>
      'Active l\'alarme d\'une habitude et elle sonne jusqu\'à ce que tu la fermes. Parfait pour les médicaments et tout ce que tu ne peux pas manquer.';

  @override
  String get whatsNewPlanTitle => 'Plan du jour';

  @override
  String get whatsNewPlanDesc =>
      'Passe ton écran d\'accueil sur le Plan du jour pour voir tes habitudes réparties dans la journée.';

  @override
  String get whatsNewStrengthTitle => 'Force au fil du temps';

  @override
  String get whatsNewStrengthDesc =>
      'Vois chaque habitude se renforcer grâce à un graphique directement dans ses détails.';

  @override
  String get whatsNewThemesTitle => 'Nouvelles couleurs de thème';

  @override
  String get whatsNewThemesDesc =>
      'Personnalise Habitt avec de nouvelles couleurs d\'accent, gratuites pour tout le monde.';

  @override
  String get scheduleReminderTitle => 'Mettre à jour ton rappel ?';

  @override
  String get scheduleReminderDescReplace =>
      'Tes rappels actuels seront remplacés par un seul rappel à l\'heure que tu choisis.';

  @override
  String get scheduleReminderDescAdd =>
      'Choisis quand tu veux être rappelé pour cette habitude.';

  @override
  String get scheduleReminderDescOff =>
      'Les rappels sont désactivés pour cette habitude. Choisir une heure les active avec un seul rappel.';

  @override
  String get scheduleReminderAtTime => 'À l\'heure exacte';

  @override
  String get scheduleReminderAtStart => 'À l\'heure de début';

  @override
  String scheduleReminderMinutesBefore(int minutes) {
    return '$minutes minutes avant';
  }

  @override
  String get requestFeature => 'Proposer une fonctionnalité';

  @override
  String premadeHealthSyncAllow(Object source) {
    return 'Tu dois autoriser l\'accès à $source pour que la synchro fonctionne.';
  }

  @override
  String get healthDeviceTitle => 'Synchro santé depuis';

  @override
  String get healthDeviceThisDevice => 'Cet appareil';

  @override
  String get healthDeviceIosOnlyNote =>
      'Les habitudes Activité et Pleine conscience ne se synchronisent que depuis un iPhone.';

  @override
  String healthCardFromDevice(Object device) {
    return 'Depuis $device';
  }

  @override
  String get backupFoundDescICloud =>
      'Ton iCloud contient déjà une sauvegarde. Comment souhaites-tu la restaurer ? La synchronisation ne démarrera pas tant que tu n\'auras pas choisi une option.';

  @override
  String get ignoreBackupUploadMine => 'Ignorer la sauvegarde';

  @override
  String get replaceCloudBackupTitle => 'Remplacer la sauvegarde existante ?';

  @override
  String replaceCloudBackupDesc(String cloud) {
    return 'La sauvegarde existante dans $cloud sera définitivement supprimée et remplacée par les données de cet appareil. Cette action est irréversible.';
  }

  @override
  String get replaceCloudBackup => 'Remplacer la sauvegarde';

  @override
  String overwriteLocalDataDescWithDate(String date) {
    return 'Es-tu sûr de vouloir remplacer tes données locales par la sauvegarde la plus récente ($date) ? Cette action est irréversible.';
  }

  @override
  String get healthForeignMetricOffTitle => 'Désactiver la synchro santé ?';

  @override
  String healthForeignMetricOffDesc(String metric) {
    return '$metric ne peut pas être lu sur ce téléphone, tu ne pourras donc pas le réactiver depuis ici.';
  }

  @override
  String get healthForeignMetricOffConfirm => 'Désactiver';

  @override
  String healthDeviceUnavailableInfo(String source) {
    return '$source n\'est pas disponible sur ce téléphone, il ne peut donc pas lire Santé.';
  }

  @override
  String get healthDeviceIosOnlyBlocked =>
      'Les habitudes Activité et Pleine conscience ne peuvent pas être suivies sur Android. Garde un iPhone comme appareil de synchro santé pour qu\'elles se synchronisent.';

  @override
  String get healthRestoreOfferTitle =>
      'Synchroniser les habitudes Santé depuis ce téléphone ?';

  @override
  String healthRestoreOfferDesc(String source) {
    return 'Tes habitudes restaurées sont liées à Santé. Ce téléphone peut les garder à jour depuis $source.';
  }

  @override
  String get healthRestoreNoneDesc =>
      'Tes habitudes Santé gardent leurs données et peuvent être modifiées à la main, mais elles ne se mettront pas à jour depuis Santé sur ce téléphone.';

  @override
  String get healthRestoreSyncHere => 'Synchroniser';

  @override
  String get healthDeviceSwitchAnyway => 'Changer quand même';

  @override
  String get healthRestoreIosOnlyDesc =>
      'Ces habitudes sont réservées à Apple Santé. Elles ne peuvent pas être synchronisées sur ce téléphone.';

  @override
  String healthSourceUnavailableTitle(String source) {
    return '$source indisponible';
  }

  @override
  String get healthRestoreAppleHealthOnly => 'Apple Santé uniquement';

  @override
  String get alarmRingingChannelName => 'Alarmes en cours';

  @override
  String get alarmSilenceAction => 'Couper';

  @override
  String get alarmSettingsTitle => 'Alarmes';

  @override
  String get alarmDndTitle => 'Sonner en mode Ne pas déranger';

  @override
  String get alarmDndDesc =>
      'Si activé, les alarmes sonneront même en mode Ne pas déranger.';

  @override
  String get alarmDndDialogTitle => 'Sonner en mode Ne pas déranger ?';

  @override
  String get alarmDndDialogTip =>
      'Tu peux le modifier à tout moment dans les réglages de notifications.';

  @override
  String get widgetDayComplete => 'Journée terminée';

  @override
  String get widgetDayCompleteBody =>
      'Toutes les habitudes sont faites. À demain.';

  @override
  String get widgetNothingToday => 'Rien de prévu aujourd\'hui';

  @override
  String get widgetStartStreak =>
      'Termine toutes tes habitudes aujourd\'hui pour lancer une série';

  @override
  String get widgetStreakName => 'Série';

  @override
  String get widgetStreakDescription =>
      'Ta série de jours parfaits et son état.';

  @override
  String get widgetStreakWeekName => 'Série de la semaine';

  @override
  String get widgetStreakWeekDescription =>
      'Ta série avec les 7 derniers jours.';

  @override
  String get widgetTodayRingName => 'Anneau du jour';

  @override
  String get widgetTodayRingDescription =>
      'Les habitudes du jour dans un anneau qui se remplit.';

  @override
  String get widgetUpNextName => 'À suivre';

  @override
  String get widgetUpNextDescription =>
      'Les habitudes de ce moment de la journée, avec ta série.';

  @override
  String get widgetOpenApp => 'Ouvre Habitt pour voir tes habitudes ici';
}
