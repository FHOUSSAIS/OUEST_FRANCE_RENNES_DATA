SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_EXECUTION
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant AGV
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_OUI : Ordre suivant trouvé
--			    @CODE_NON : Ordonnancement ou regroupement des ordres suivants nécessaires
--			    @CODE_KO_PARAM : Absence procédure stockée d'affinage spécifique
--			    @CODE_KO_VIDE : Adresse prise vide
--			    @CODE_KO_INCORRECT : Affinage incorrect
--			    @CODE_KO_SQL : Erreur SQL
--			    @CODE_KO_PLEIN : Adresse dépose pleine
--			    @CODE_KO_ADR_INCONNUE : Adresse inconnue
-- Descriptif		: @v_ord_idordre : Identifiant ordre
--			  Gestion de l'exécution d'un ordre :
--			    - Vérification de la possibilité d'exécution d'un ordre
--			      pour l'AGV
--			    - Récupération de l'ordre suivant
--			    - Affinage si besoin
--			  Il ne peut y avoir plus d'un seul ordre dans l'état envoyé.
--			  L'envoi d'un ordre n'est possible que si le précédent correspond
--			  à une action d'attente ou de maintenance
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_EXECUTION]
	@v_iag_idagv tinyint,
	@v_ord_idordre int out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_error int,
	@v_status int,
	@v_retour int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_OUI tinyint,
	@CODE_NON tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@DESC_ENVOYE tinyint

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_ATTENTE smallint,
	@ACTI_MAINTENANCE smallint

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_EXECUTION tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_OUI = 5
	SELECT @CODE_NON = 6
	SELECT @ETAT_ENATTENTE = 1
	SELECT @ETAT_ENCOURS = 2
	SELECT @DESC_ENVOYE = 13
	SELECT @ACTI_ATTENTE = 1
	SELECT @ACTI_MAINTENANCE = 256
	SELECT @AFFI_EXECUTION = 2

-- Initialisation des variables
	SELECT @v_error = 0
	SELECT @v_status = @CODE_KO
	SELECT @v_retour = @CODE_KO

	-- Vérification de la possibilité d'exécution d'un ordre
	IF NOT EXISTS ((SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = @v_iag_idagv
		AND ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE)
		UNION (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = @v_iag_idagv
		AND ORD_IDETAT = @ETAT_ENCOURS AND EXISTS (SELECT 1 FROM TACHE, ASSOCIATION_TACHE_ACTION_TACHE
		WHERE TAC_IDORDRE = ORD_IDORDRE AND ATA_IDTACHE = TAC_IDTACHE AND ATA_IDACTION NOT IN (@ACTI_ATTENTE, @ACTI_MAINTENANCE))))
	BEGIN
		-- Recherche des tâches à affiner
		IF EXISTS (SELECT 1 FROM ORDRE_AGV, TACHE A WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE AND A.TAC_IDORDRE = ORD_IDORDRE
			AND A.TAC_POSITION_TACHE = (SELECT MIN(B.TAC_POSITION_TACHE) FROM TACHE B WHERE B.TAC_IDMISSION = A.TAC_IDMISSION
			AND B.TAC_IDETAT = @ETAT_ENATTENTE) AND TAC_AFFINAGEADR = @AFFI_EXECUTION)
		BEGIN
			EXEC @v_status = SPV_AFFINEEXECUTION 0, @v_iag_idagv
			SELECT @v_error = @@ERROR
			IF @v_status = @CODE_OK AND @v_error = 0
				SELECT @v_retour = @CODE_OK
			ELSE
				SELECT @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
		END
		ELSE
			SELECT @v_retour = @CODE_OK
		IF @v_retour = @CODE_OK
		BEGIN
			IF (SELECT COUNT(DISTINCT ORD_IDORDRE) FROM ORDRE_AGV, TACHE A WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE AND A.TAC_IDORDRE = ORD_IDORDRE
				AND A.TAC_POSITION_TACHE = (SELECT MIN(B.TAC_POSITION_TACHE) FROM TACHE B WHERE B.TAC_IDMISSION = A.TAC_IDMISSION
				AND B.TAC_IDETAT = @ETAT_ENATTENTE)
				AND NOT EXISTS (SELECT 1 FROM TACHE C WHERE C.TAC_IDETAT = @ETAT_ENATTENTE AND C.TAC_IDORDRE = ORD_IDORDRE AND C.TAC_POSITION_TACHE <> (SELECT MIN(D.TAC_POSITION_TACHE) FROM TACHE D WHERE D.TAC_IDMISSION = C.TAC_IDMISSION AND D.TAC_IDETAT = @ETAT_ENATTENTE))) > 1
				SELECT @v_retour = @CODE_NON
		END
		IF @v_retour = @CODE_OK
		BEGIN
			-- Récupération de l'ordre suivant
			SELECT TOP 1 @v_ord_idordre = ORD_IDORDRE FROM ORDRE_AGV
				WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE
				ORDER BY ORD_POSITION
			IF @v_ord_idordre IS NOT NULL
			BEGIN
				-- Recherche des adresses à affiner
				EXEC @v_status = SPV_AFFINEADRESSE 0, @v_iag_idagv, @v_ord_idordre
				SELECT @v_error = @@ERROR
				IF @v_status = @CODE_OK AND @v_error = 0
					SELECT @v_retour = @CODE_OUI
				ELSE
					SELECT @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END		
			END
			ELSE
				SELECT @v_retour = @CODE_OK
		END
	END
	ELSE
		SELECT @v_retour = @CODE_OK
	RETURN @v_retour

