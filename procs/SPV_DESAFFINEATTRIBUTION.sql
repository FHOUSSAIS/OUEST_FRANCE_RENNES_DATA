SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF







-----------------------------------------------------------------------------------------
-- Procedure		: SPV_DESAFFINEATTRIBUTION
-- Paramètre d'entrée	: @v_mis_idmission : Identifiant mission
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_SQL : Erreur SQL
-- Descriptif		: Désaffinage d'une mission à l'attribution
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_DESAFFINEATTRIBUTION]
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
	@v_tac_idsousbaseexecution bigint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_ATTRIBUTION tinyint
	
-- Déclaration des constantes de traces
DECLARE
	@TRAC_AFFINAGE tinyint
	
-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @AFFI_ATTRIBUTION = 1
	SET @TRAC_AFFINAGE = 20

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	BEGIN TRAN
	-- Mise à jour des tâches
	DECLARE c_tache CURSOR LOCAL FOR SELECT TAC_IDTACHE FROM TACHE
		WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_AFFINAGEADR = @AFFI_ATTRIBUTION
		FOR UPDATE
	OPEN c_tache
	FETCH NEXT FROM c_tache INTO @v_tac_idtache
	WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
	BEGIN
		SET @v_tac_idsystemeexecution = NULL
		SET @v_tac_idbaseexecution = NULL
		SET @v_tac_idsousbaseexecution = NULL
		SELECT TOP 1 @v_tac_idsystemeexecution = TMI_ADRSYS, @v_tac_idbaseexecution = TMI_ADRBASE, @v_tac_idsousbaseexecution = TMI_ADRSSBASE
			FROM TRACE_MISSION WHERE TMI_IDMISSION = @v_mis_idmission AND TMI_IDTACHE = @v_tac_idtache AND TMI_TYPETRC = @TRAC_AFFINAGE
			ORDER BY TMI_ID
		IF @v_tac_idsystemeexecution IS NOT NULL AND @v_tac_idbaseexecution IS NOT NULL AND @v_tac_idsousbaseexecution IS NOT NULL
			UPDATE TACHE SET TAC_IDADRSYS = @v_tac_idsystemeexecution, TAC_IDADRBASE = @v_tac_idbaseexecution, TAC_IDADRSSBASE = @v_tac_idsousbaseexecution
				WHERE CURRENT OF c_tache
		SET @v_error = @@ERROR
		FETCH NEXT FROM c_tache INTO @v_tac_idtache
	END
	CLOSE c_tache
	DEALLOCATE c_tache
	IF @v_error = 0
		SET @v_retour = @CODE_OK
	ELSE
		SET @v_retour = @CODE_KO_SQL
	IF @v_retour <> @CODE_OK
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_retour

