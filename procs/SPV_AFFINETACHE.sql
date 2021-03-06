SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF





-----------------------------------------------------------------------------------------
-- Procedure		: SPV_AFFINETACHE
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant AGV
--			  @v_tac_idtache : Identifiant tâche
--			  @v_tac_affinage : Type d'affinage
--			    1 : Affinage à l'attribution
--			    2 : Affinage à l'exécution
-- Paramètre de sortie	: @v_tac_idsystemeexecution : Clé système d'exécution
--			  @v_tac_idbaseexecution : Clé base d'exécution
--			  @v_tac_idsousbaseexecution : Clé sous-base d'exécution
--			  @v_tac_idsystemeexecution : Clé système d'affinage
--			  @v_tac_idbaseexecution : Clé base d'affinage
--			  @v_tac_idsousbaseexecution : Clé sous-base d'affinage
--			  @v_tac_accesbase : Côté d'accès à la base
--			  Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_PARAM : Absence procédure stockée d'affinage spécifique
--			    @CODE_KO_INCORRECT : Affinage incorrect
--			    @CODE_KO_SPECIFIQUE : Refus d'affinage spécifique
--			    @CODE_KO_ADR_INCONNUE : Adresse inconnue
-- Descriptif		: Affinage d'une tâche
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_AFFINETACHE]
	@v_iag_idagv tinyint,
	@v_tac_idtache int,
	@v_tac_affinage tinyint,
	@v_tac_idsystemeexecution bigint out,
	@v_tac_idbaseexecution bigint out,
	@v_tac_idsousbaseexecution bigint out,
	@v_tac_idsystemeaffinage bigint out,
	@v_tac_idbaseaffinage bigint out,
	@v_tac_idsousbaseaffinage bigint out,
	@v_tac_accesbase bit out
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
	@v_retour int,
	@v_par_valeur varchar(128),
	@v_act_occupation smallint,
	@v_bas_type bit,
	@v_adr_type bit

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_PARAM tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SPECIFIQUE tinyint,
	@CODE_KO_ADR_INCONNUE tinyint

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_ATTRIBUTION tinyint,
	@AFFI_EXECUTION tinyint

-- Déclaration des constantes de types d'actions
DECLARE
	@ACTI_PRIMAIRE bit

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_PARAM = 8
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SPECIFIQUE = 20
	SET @CODE_KO_ADR_INCONNUE = 28
	SET @AFFI_ATTRIBUTION = 1
	SET @AFFI_EXECUTION = 2
	SET @ACTI_PRIMAIRE = 0

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO

	-- Récupération de la procédure stockée d'affinage spécifique
	SELECT @v_par_valeur = CASE PAR_VAL WHEN '' THEN NULL ELSE PAR_VAL END FROM PARAMETRE WHERE PAR_NOM = 'AFFINE_TACHE'
	IF (@v_par_valeur IS NOT NULL)
	BEGIN
		IF @v_tac_affinage = @AFFI_ATTRIBUTION
			EXEC @v_status = @v_par_valeur @v_iag_idagv, @v_tac_idtache, @v_tac_idsystemeexecution out,
				@v_tac_idbaseexecution out, @v_tac_idsousbaseexecution out, NULL, NULL, NULL, @v_tac_accesbase out
		ELSE IF @v_tac_affinage = @AFFI_EXECUTION
			EXEC @v_status = @v_par_valeur @v_iag_idagv, @v_tac_idtache, @v_tac_idsystemeexecution out,
				@v_tac_idbaseexecution out, @v_tac_idsousbaseexecution out, @v_tac_idsystemeaffinage out,
				@v_tac_idbaseaffinage out, @v_tac_idsousbaseaffinage out, @v_tac_accesbase out
		SET @v_error = @@ERROR
		IF @v_status = @CODE_OK AND @v_error = 0
		BEGIN
			-- Contrôle de l'existence de l'adresse
			IF EXISTS (SELECT 1 FROM ADRESSE WHERE ADR_SYSTEME = @v_tac_idsystemeexecution AND ADR_BASE = @v_tac_idbaseexecution AND ADR_SOUSBASE = @v_tac_idsousbaseexecution)
			BEGIN
				-- Récupération des informations de l'action de la tâche
				SELECT @v_act_occupation = ACT_OCCUPATION FROM TACHE, ASSOCIATION_TACHE_ACTION_TACHE, ACTION WHERE TAC_IDTACHE = @v_tac_idtache
					AND ATA_IDTACHE = TAC_IDTACHE AND ACT_IDACTION = ATA_IDACTION AND ATA_IDTYPEACTION = @ACTI_PRIMAIRE
				-- Récupération des informations de l'adresse
				SELECT @v_bas_type = BAS_TYPE, @v_adr_type = ADR_TYPE
					FROM BASE, ADRESSE WHERE BAS_SYSTEME = @v_tac_idsystemeexecution AND BAS_BASE = @v_tac_idbaseexecution AND ADR_SYSTEME = BAS_SYSTEME AND ADR_BASE = BAS_BASE
					AND ADR_SOUSBASE = @v_tac_idsousbaseexecution
				-- Contrôle de la cohérence du type de base et du type d'affinage
				IF ((@v_tac_affinage = @AFFI_ATTRIBUTION AND @v_bas_type = 1 AND (@v_adr_type = 1 OR @v_act_occupation <> 1))
					OR (@v_tac_affinage = @AFFI_EXECUTION AND ((@v_tac_idsystemeaffinage IS NULL AND @v_tac_idbaseaffinage IS NULL AND @v_tac_idsousbaseaffinage IS NULL
					AND @v_bas_type = 1 AND (@v_adr_type = 1 OR @v_act_occupation <> 1))
					OR EXISTS (SELECT 1 FROM BASE WHERE BAS_SYSTEME = @v_tac_idsystemeaffinage AND BAS_BASE = @v_tac_idbaseaffinage
					AND BAS_TYPE = 1))))
				BEGIN
					IF (@v_tac_affinage = @AFFI_EXECUTION AND @v_adr_type = 1)
						SELECT @v_tac_idsystemeaffinage = NULL, @v_tac_idbaseaffinage = NULL, @v_tac_idsousbaseaffinage = NULL
					SET @v_retour = @CODE_OK
				END
				ELSE
					SET @v_retour = @CODE_KO_INCORRECT
			END
			ELSE
				SET @v_retour = @CODE_KO_ADR_INCONNUE
		END
		ELSE
			SET @v_retour = @CODE_KO_SPECIFIQUE
	END
	ELSE
		SET @v_retour = @CODE_KO_PARAM
	RETURN @v_retour

