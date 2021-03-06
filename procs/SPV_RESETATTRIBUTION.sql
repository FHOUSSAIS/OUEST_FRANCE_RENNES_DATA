SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_RESETATTRIBUTION
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant de l'AGV
-- Paramètre de sortie	: 
-- Descriptif		: Réinitialisation de l'attribution
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_RESETATTRIBUTION]
	@v_iag_idagv tinyint
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
	@v_retour smallint,
	@v_mis_idmission int,
	@v_tac_idtache int,
	@v_tac_idsystemeexecution bigint,
	@v_tac_idbaseexecution bigint,
	@v_tac_idsousbaseexecution bigint	
	
-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ANNULE tinyint,
	@ETAT_TERMINE tinyint,
	@DESC_ANNULATION tinyint

--Déclaration des constantes de type de missions
DECLARE
	@TYPE_MOUVEMENT tinyint
	
-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_ATTRIBUTION tinyint
	
-- Déclaration des constantes de traces
DECLARE
	@TRAC_AFFINAGE tinyint

-- Déclaration des constantes de mode d'exploitation
DECLARE
	@MODE_TEST int

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_ANNULATION = 9
	SET @TYPE_MOUVEMENT = 3
	SET @AFFI_ATTRIBUTION = 1
	SET @TRAC_AFFINAGE = 20
	SET @MODE_TEST = 1

-- Initialisation de la variable de retour
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	BEGIN TRAN
	-- Démarquage des missions marquées
	UPDATE MISSION SET MIS_MARQUE = 0 WHERE MIS_IDETAT = @ETAT_ENATTENTE AND MIS_MARQUE = 1	
	-- Désaffinage des missions en attente
	DECLARE c_tache CURSOR LOCAL FOR SELECT MIS_IDMISSION, TAC_IDTACHE FROM INT_MISSION_VIVANTE INNER JOIN INT_TACHE_MISSION ON TAC_IDMISSION = MIS_IDMISSION
		WHERE MIS_IDETATMISSION = @ETAT_ENATTENTE AND TAC_AFFINAGE = @AFFI_ATTRIBUTION
	OPEN c_tache
	FETCH NEXT FROM c_tache INTO @v_mis_idmission, @v_tac_idtache
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
				WHERE TAC_IDTACHE = @v_tac_idtache
		SET @v_error = @@ERROR
		FETCH NEXT FROM c_tache INTO @v_mis_idmission, @v_tac_idtache
	END
	CLOSE c_tache
	DEALLOCATE c_tache
	IF EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv AND IAG_MODE_EXPLOIT <> @MODE_TEST)
	BEGIN
		-- Suppression des missions de mouvement en attente associées à l'AGV
		IF EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDTYPEMISSION = @TYPE_MOUVEMENT AND MIS_IDAGV = @v_iag_idagv
			AND MIS_IDETATMISSION = @ETAT_ENATTENTE)
		BEGIN
			DECLARE c_tache CURSOR LOCAL FAST_FORWARD FOR SELECT TAC_IDTACHE
				FROM INT_TACHE_MISSION WHERE TAC_IDMISSION IN (SELECT MIS_IDMISSION FROM INT_MISSION_VIVANTE WHERE MIS_IDTYPEMISSION = @TYPE_MOUVEMENT AND MIS_IDAGV = @v_iag_idagv
				AND MIS_IDETATMISSION = @ETAT_ENATTENTE) AND TAC_IDETATTACHE NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
			OPEN c_tache
			FETCH NEXT FROM c_tache INTO @v_tac_idtache
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				UPDATE TACHE SET TAC_IDETAT = @ETAT_ANNULE, TAC_DSCETAT = @DESC_ANNULATION WHERE TAC_IDTACHE = @v_tac_idtache
				SET @v_error = @@ERROR
				FETCH NEXT FROM c_tache INTO @v_tac_idtache
			END
			CLOSE c_tache
			DEALLOCATE c_tache
		END
	END
	IF @v_error = 0
	BEGIN
		SET @v_retour = @CODE_OK
		COMMIT TRAN
	END
	ELSE
	BEGIN
		SET @v_retour = @v_error
		ROLLBACK TRAN
	END
	RETURN @v_retour

