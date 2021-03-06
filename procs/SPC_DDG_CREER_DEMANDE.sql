SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Menu de création d'une Demande de Rangement
-- @v_idSystemePrise		: Système de la base de prise
-- @v_idBasePrise	: Base de la base de prise
-- @v_idSousBasePrise	: Sous base de la base de prise
-- @v_idSystemeDepose		: Système de la base de prise
-- @v_idBaseDepose		: Base de la base de prise
-- @v_idSousBaseDepose	: Sous Base de la base de prise
-- @v_nbBobines			: Nombre de bobine
-- @v_priorite			: priorité de la mission
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DDG_CREER_DEMANDE]
	@v_idSystemePrise	BIGINT,
	@v_idBasePrise		BIGINT,
	@v_idSousBasePrise	BIGINT,
	@v_idSystemeDepose	BIGINT,
	@v_idBaseDepose		BIGINT,
	@v_idSousBaseDepose	BIGINT,
	@v_nbBobines		INT = 0,
	@v_priorite			INT = 0
AS
BEGIN

DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1
DECLARE @CODE_KO_ALLEE_VIDE INT = -1456
DECLARE @CODE_KO_ALLEE_PRISE_VERIF INT = -1457
DECLARE @CODE_KO_ALLEE_PLEINE INT = -1458
DECLARE @CODE_KO_ALLEE_DEPOSE_VERIF INT = -1459
DECLARE @CODE_KO_DIFF_CARAC_BOBINES INT = -1460
DECLARE @CODE_KO_ALLEE_PRISE_DEMANDEE INT = -1468
DECLARE @CODE_KO_ALLEE_DEPOSE_DEMANDEE INT = -1469

DECLARE @ETAT_DMD_NOUVELLE INT = 0

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demande Reorganisation'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

declare @v_idDemande VARCHAR(20)
declare @nbBobineAlleePrise int -- Nombre de bobines dans l'allée de prise
declare @AlleePriseAVerifier int
declare @AlleeDeposeAVerifier int
declare @AlleeAutPrise int -- Nombre de bobines dans l'allée de prise
declare @AlleeAutDepose int -- Nombre de bobines dans l'allée de dépose
declare @AlleeEtatPrise int
declare @AlleeEtatDepose int
declare @nbPlaceAlleeDepose int
declare @LaizePrise			int
declare @DiametrePrise		int
declare @FournisseurPrise	int
declare @GrammagePrise		numeric(5,2)
declare @LaizeDepose		int
declare @DiametreDepose		int
declare @FournisseurDepose	int
declare @GrammageDepose		numeric(5,2)
DECLARE @NbBobinesMax		int
DECLARE @HauteurInitiale	int
DECLARE @HauteurCourante	int

SET @trace = 'SPC_DDG_CREER_DEMANDE : ' 
				+ '@v_idSystemePrise =' + ISNULL(CONVERT(VARCHAR, @v_idSystemePrise), 'NULL')
				+ ', @v_idBasePrise =' + ISNULL(CONVERT(VARCHAR, @v_idBasePrise), 'NULL')
				+ ', @v_idSousBasePrise = ' + ISNULL(CONVERT(VARCHAR, @v_idSousBasePrise), 'NULL')
				+ ', @v_idSystemeDepose = ' + ISNULL(CONVERT(VARCHAR, @v_idSystemeDepose), 'NULL')
				+ ', @v_idBaseDepose = ' + ISNULL(CONVERT(VARCHAR, @v_idBaseDepose), 'NULL')
				+ ', @v_idSousBaseDepose = ' + ISNULL(CONVERT(VARCHAR, @v_idSousBaseDepose), 'NULL')
				+ ', @v_nbBobines = ' + ISNULL(CONVERT(VARCHAR, @v_nbBobines), 'NULL')
				+ ', @v_priorite = ' + ISNULL(CONVERT(VARCHAR, @v_priorite), 'NULL')

SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

/*Récuperation des infos des adresses*/
SELECT
	@AlleeEtatPrise = ADR_IDETAT_OCCUPATION,
	@nbBobineAlleePrise = ADR_EMPLACEMENT_OCCUPE,
	@AlleePriseAVerifier = ADR_VERIFICATION,
	@AlleeAutPrise = ADR_AUTORISATIONPRISE,
	@LaizePrise = SCB_LAIZE,
	@DiametrePrise = SCB_DIAMETRE,
	@FournisseurPrise = SCB_IDFOURNISSEUR,
	@GrammagePrise = SCB_GRAMMAGE
FROM INT_ADRESSE
INNER JOIN INT_CHARGE_VIVANTE
	ON ADR_IDSYSTEME = CHG_IDSYSTEME
	AND ADR_IDBASE = CHG_IDBASE
	AND ADR_IDSOUSBASE = CHG_IDSOUSBASE
INNER JOIN SPC_CHARGE_BOBINE on SCB_IDCHARGE = CHG_IDCHARGE
WHERE ADR_IDSYSTEME = @v_idSystemePrise
AND ADR_IDBASE = @v_idBasePrise
AND ADR_IDSOUSBASE = @v_idSousBasePrise

SELECT
	@AlleeEtatDepose = ADR_IDETAT_OCCUPATION,
	@AlleeAutDepose = ADR_AUTORISATIONDEPOSE,
	@AlleeDeposeAVerifier = ADR_VERIFICATION,
	@nbPlaceAlleeDepose = ADR_EMPLACEMENT_VIDE,
	@LaizeDepose = SCB_LAIZE,
	@DiametreDepose = SCB_DIAMETRE,
	@FournisseurDepose = SCB_IDFOURNISSEUR,
	@GrammageDepose = SCB_GRAMMAGE
FROM INT_ADRESSE
INNER JOIN INT_CHARGE_VIVANTE
	ON ADR_IDSYSTEME = CHG_IDSYSTEME
	AND ADR_IDBASE = CHG_IDBASE
	AND ADR_IDSOUSBASE = CHG_IDSOUSBASE
INNER JOIN SPC_CHARGE_BOBINE on SCB_IDCHARGE = CHG_IDCHARGE
WHERE ADR_IDSYSTEME = @v_idSystemeDepose
AND ADR_IDBASE = @v_idBaseDepose
AND ADR_IDSOUSBASE = @v_idSousBaseDepose

-- Calcul du nombre de places libres en dépose
select @HauteurInitiale = STRUCTURE.STR_HAUTEUR_INITIALE from STRUCTURE 
		where STRUCTURE.STR_SYSTEME = @v_idSystemeDepose
				AND STRUCTURE.STR_BASE = @v_idBaseDepose
				AND STRUCTURE.STR_SOUSBASE = @v_idSousBaseDepose

-- Si la base est contraintes par rapport à ce type de laize
IF EXISTS (select 1 from SPC_STK_NBLAIZEHAUTEUR
inner join SPC_CHG_TYPE_LAIZE on SPC_CHG_TYPE_LAIZE.SLT_ID = SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE
inner join SPC_CHG_LAIZE on SPC_CHG_LAIZE.SCL_TYPE_LAIZE = SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE
where SPC_CHG_LAIZE.SCL_LAIZE = @LaizePrise
	AND SPC_STK_NBLAIZEHAUTEUR.NLH_IDSYSTEME = @v_idSystemeDepose
	AND SPC_STK_NBLAIZEHAUTEUR.NLH_IDBASE = @v_idBaseDepose
	AND SPC_STK_NBLAIZEHAUTEUR.NLH_IDSOUSBASE = @v_idsousbasedepose)
BEGIN
	--On calcul la hauteur max contrainte et on la compare avec la hauteur max de la base
	--Nombre de bobines max
	select @NbBobinesMax = SPC_STK_NBLAIZEHAUTEUR.NLH_NBBOBINES from SPC_STK_NBLAIZEHAUTEUR
		inner join SPC_CHG_TYPE_LAIZE on SPC_CHG_TYPE_LAIZE.SLT_ID = SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE
		inner join SPC_CHG_LAIZE on SPC_CHG_LAIZE.SCL_TYPE_LAIZE = SPC_STK_NBLAIZEHAUTEUR.NLH_TYPELAIZE
		where SPC_CHG_LAIZE.SCL_LAIZE = @LaizePrise

	--Calcul de la hauteur correspondante par rapport à la laize
	SET @HauteurCourante = @NbBobinesMax * @LaizePrise

	--On prend le minimum des 2
	IF @HauteurCourante > @HauteurInitiale
		SET @HauteurCourante = @HauteurInitiale

	--Changement de la hauteur courante dans la table structure
	UPDATE STRUCTURE set STR_HAUTEUR_COURANTE = @HauteurCourante where STRUCTURE.STR_SYSTEME = @v_idSystemeDepose
							AND STRUCTURE.STR_BASE = @v_idBaseDepose
							and STRUCTURE.STR_SOUSBASE = @v_idSousBaseDepose

END
ELSE -- Pas de contraintes, la hauteur courante = hauteur initiale
BEGIN
	UPDATE STRUCTURE set STR_HAUTEUR_COURANTE = @HauteurInitiale where STRUCTURE.STR_SYSTEME = @v_idSystemeDepose
							AND STRUCTURE.STR_BASE = @v_idBaseDepose
							and STRUCTURE.STR_SOUSBASE = @v_idSousBaseDepose
END

-- Calcul du nombre de place sidpo dans l'allée
exec @nbPlaceAlleeDepose = dbo.INT_GETCAPACITE @v_idSystemeDepose, @v_idBaseDepose, @v_idSousBaseDepose,1, 0, @LaizePrise, @DiametrePrise, @DiametrePrise,0 , 0

SET @trace = 'SPC_DDG_CREER_DEMANDE : ' 
				+ '@nbPlaceAlleeDepose =' + ISNULL(CONVERT(VARCHAR, @nbPlaceAlleeDepose), 'NULL')
				+ ', @HauteurInitiale =' + ISNULL(CONVERT(VARCHAR, @HauteurInitiale), 'NULL')
				+ ', @HauteurCourante = ' + ISNULL(CONVERT(VARCHAR, @HauteurCourante), 'NULL')
				+ ', @NbBobinesMax = ' + ISNULL(CONVERT(VARCHAR, @NbBobinesMax), 'NULL')
				
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'DEBUG',
							@v_trace = @trace

-- Si Nb > Bobine dans l'allée 
-- Alors Nb = 0 => Allée  complète
IF @v_nbBobines > @nbBobineAlleePrise
BEGIN
	SET @v_nbBobines = 0
	SET @retour = @CODE_OK
END

-- Si allée complète demandée
IF @v_nbBobines = 0
BEGIN
	SELECT @v_nbBobines = COUNT(1) from INT_CHARGE_VIVANTE
		WHERE CHG_IDSYSTEME = @v_idSystemePrise
		AND CHG_IDBASE = @v_idBasePrise
		AND CHG_IDSOUSBASE = @v_idSousBasePrise
END


-- Si Nb > 0 et Pas de Bobine dans l'allée
-- Alors Retour Erreur : "Pas de Bobine dans l'allée de Prise"
IF (@v_nbBobines > 0 AND (@nbBobineAlleePrise = 0  OR @AlleeEtatPrise = 1))
BEGIN
SET @retour = @CODE_KO_ALLEE_VIDE
SET @trace = 'Pas de bobines dans allée : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'ERREUR',
							@v_trace = @trace
END

-- Si Allée A Vérifier ou Interdite en prise
-- Alors Retour Erreur : "Vérifier Etat Allée Prise"
ELSE IF @AlleeAutPrise = 0 OR @AlleePriseAVerifier = 1
BEGIN
SET @retour = @CODE_KO_ALLEE_PRISE_VERIF
SET @trace = 'Allée a verifier : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'ERREUR',
							@v_trace = @trace
END

-- Si l'allée de prise est déjà affectée à une demande de réorga ou d'appro demac
-- Alors Retour Erreur : "Allée de Prise déjà associée à une demande"
ELSE IF EXISTS (SELECT 1 from SPC_DMD_REORGA_STOCK_GENERAL where SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDSYSTEME_PRISE = @v_idSystemePrise
	AND SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDBASE_PRISE = @v_idBasePrise
	AND SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDSOUSBASE_PRISE = @v_idSousBasePrise)
	OR EXISTS (SELECT 1 from SPC_DMD_REORGA_STOCK_GENERAL where SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDSYSTEME_DEPOSE = @v_idSystemePrise
	AND SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDBASE_DEPOSE = @v_idBasePrise
	AND SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDSOUSBASE_DEPOSE = @v_idSousBasePrise)
BEGIN
SET @retour = @CODE_KO_ALLEE_PRISE_DEMANDEE
SET @trace = 'Allée de Prise déjà associée à une demande: ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'ERREUR',
							@v_trace = @trace
END

-- Vérification Dépose
-- Si Nb > Nombre de place restantes dans Dépose
-- Alors Retour Erreur : "Pas assez de place dans l'allée de Dépose"
ELSE IF @nbPlaceAlleeDepose < @v_nbBobines AND @nbPlaceAlleeDepose IS NOT NULL
BEGIN
SET @retour = @CODE_KO_ALLEE_PLEINE
SET @trace = 'Pas assez de places an dépose: ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'ERREUR',
							@v_trace = @trace
END

-- Si Caractéristiques Différentes entre Bobine Prise et Dépose
-- Alors Retour Erreur : "Les caractéristiques des Bobines sont Différentes"
ELSE IF ((@LaizePrise <> @LaizeDepose AND @LaizeDepose IS NOT NULL)
	OR (@DiametrePrise <> @DiametreDepose AND @DiametreDepose IS NOT NULL)
	OR (@FournisseurPrise <> @FournisseurDepose and @FournisseurDepose IS NOT NULL)
	OR (@GrammagePrise <> @GrammageDepose AND @GrammageDepose IS NOT NULL))
BEGIN
SET @retour = @CODE_KO_DIFF_CARAC_BOBINES
SET @trace = 'Les caractéristiques des Bobines sont Différentes: ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'ERREUR',
							@v_trace = @trace
END

-- Si Allée A Vérifier ou Interdite en dépose
-- Alors Retour Erreur : "Vérifier Etat Allée Dépose"
ELSE IF @AlleeAutDepose = 0 OR @AlleeDeposeAVerifier = 1
BEGIN
SET @retour = @CODE_KO_ALLEE_DEPOSE_VERIF
SET @trace = 'Allée de dépose a verifier : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'ERREUR',
							@v_trace = @trace
END

-- Si l'allée de dépose est déjà affectée à une demande de réorga ou d'appro demac
-- Alors Retour Erreur : "Allée de Dépose déjà associée à une demande"
ELSE IF EXISTS (SELECT 1 from SPC_DMD_REORGA_STOCK_GENERAL where SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDSYSTEME_PRISE = @v_idSystemeDepose
	AND SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDBASE_PRISE = @v_idBaseDepose
	AND SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDSOUSBASE_PRISE = @v_idSousBaseDepose)
	OR EXISTS (SELECT 1 from SPC_DMD_REORGA_STOCK_GENERAL where SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDSYSTEME_DEPOSE = @v_idSystemeDepose
	AND SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDBASE_DEPOSE = @v_idBaseDepose
	AND SPC_DMD_REORGA_STOCK_GENERAL.SDG_IDSOUSBASE_DEPOSE = @v_idSousBaseDepose)
BEGIN
SET @retour = @CODE_KO_ALLEE_DEPOSE_DEMANDEE
SET @trace = 'Allée de Dépose déjà associée à une demande: ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
SET @trace = @procStock + '/' + @trace
EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
							@v_log_idlog = 'ERREUR',
							@v_trace = @trace
END

IF @retour = @CODE_OK
BEGIN
	-- Récupération de l'identifiant dans une table de paramétrage + Ajout Préfixe "RG_"
	SELECT
		@v_idDemande = SDC_COMPTEUR + 1
	FROM SPC_DMD_COMPTEUR
	WHERE SDC_IDCOMPTEUR = 1
		
	INSERT INTO [dbo].[SPC_DMD_REORGA_STOCK_GENERAL] ([SDG_IDDEMANDE], [SDG_IDSYSTEME_PRISE], [SDG_IDBASE_PRISE], [SDG_IDSOUSBASE_PRISE]
	, [SDG_IDSYSTEME_DEPOSE], [SDG_IDBASE_DEPOSE], [SDG_IDSOUSBASE_DEPOSE]
	, [SDG_NBADEPLACER], [SDG_NBRESTANT], [SDG_ETAT], [SDG_DATE], [SDG_PRIORITE])
		VALUES ('RG_'+@v_idDemande, @v_idSystemePrise, @v_idBasePrise, @v_idSousBasePrise, @v_idSystemeDepose, @v_idBaseDepose, @v_idSousBaseDepose, @v_nbBobines, @v_nbBobines, 0, GETDATE(), @v_priorite)
	SET @retour = @@ERROR
	
	IF (@retour <> @CODE_OK) 
	BEGIN
		SET @trace = 'INSERT INTO SPC_DMD_REORGA_STOCK_GENERAL : ' + ISNULL(CONVERT(VARCHAR, @retour), 'NULL')
		SET @trace = @procStock + '/' + @trace
		EXEC INT_ADDTRACESPECIFIQUE	@v_mon_idmoniteur = @moniteur,
									@v_log_idlog = 'ERREUR',
									@v_trace = @trace
	END
	ELSE
	BEGIN
		UPDATE SPC_DMD_COMPTEUR
		SET SDC_COMPTEUR = @v_idDemande
		WHERE SDC_IDCOMPTEUR = 1
	END
END


RETURN @retour

END
