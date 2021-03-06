SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF






-----------------------------------------------------------------------------------------
-- Procedure		: SPV_AFFINEATTRIBUTION
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant AGV
--			  @v_mis_idmission : Identifiant mission
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_PARAM : Absence procédure stockée d'affinage spécifique
--			    @CODE_KO_INCORRECT : Affinage incorrect
--			    @CODE_KO_SQL : Erreur SQL
--			    @CODE_KO_ADR_INCONNUE : Adresse inconnue
-- Descriptif		: Affinage d'une tâche à l'attribution
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_AFFINEATTRIBUTION]
	@v_iag_idagv tinyint,
	@v_mis_idmission int
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
	@v_tac_idtache int,
	@v_tac_idsystemeexecution bigint,
	@v_tac_idbaseexecution bigint,
	@v_tac_idsousbaseexecution bigint,
	@v_tac_idsystemeaffinage bigint,
	@v_tac_idbaseaffinage bigint,
	@v_tac_idsousbaseaffinage bigint,
	@v_tac_accesbase bit

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_ATTRIBUTION tinyint

-- Définition des constantes
	SELECT @CODE_OK = 0
	SELECT @CODE_KO = 1
	SELECT @CODE_KO_SQL = 13
	SELECT @AFFI_ATTRIBUTION = 1

-- Initialisation des variables
	SELECT @v_error = 0
	SELECT @v_status = @CODE_OK
	SELECT @v_retour = @CODE_KO

	BEGIN TRAN
	-- Récupération des tâches à affiner
	DECLARE c_tache CURSOR LOCAL FOR SELECT TAC_IDTACHE, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE, TAC_ACCES_BASE
		FROM TACHE WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_AFFINAGEADR = @AFFI_ATTRIBUTION
		ORDER BY TAC_POSITION_TACHE
	OPEN c_tache
	FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution, @v_tac_accesbase
	WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
	BEGIN
		-- Appel de l'affinage spécifique
		EXEC @v_status = SPV_AFFINETACHE @v_iag_idagv, @v_tac_idtache, @AFFI_ATTRIBUTION,
			@v_tac_idsystemeexecution out, @v_tac_idbaseexecution out, @v_tac_idsousbaseexecution out,
			NULL, NULL, NULL, @v_tac_accesbase out
		SELECT @v_error = @@ERROR
		IF @v_status = @CODE_OK AND @v_error = 0
		BEGIN
			-- Mise à jour de la tâche
			UPDATE TACHE SET TAC_IDADRSYS = @v_tac_idsystemeexecution, TAC_IDADRBASE = @v_tac_idbaseexecution, TAC_IDADRSSBASE = @v_tac_idsousbaseexecution,
				TAC_ACCES_BASE = @v_tac_accesbase WHERE TAC_IDTACHE = @v_tac_idtache
			SELECT @v_error = @@ERROR
			IF @v_error <> 0
				SELECT @v_retour = @CODE_KO_SQL
		END
		FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution, @v_tac_accesbase
	END
	CLOSE c_tache
	DEALLOCATE c_tache
	IF @v_status = @CODE_OK AND @v_error = 0
		SELECT @v_retour = @CODE_OK
	ELSE
		SELECT @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
	IF @v_retour <> @CODE_OK
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_retour

