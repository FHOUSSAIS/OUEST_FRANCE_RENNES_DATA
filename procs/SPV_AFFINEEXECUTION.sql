SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON







-----------------------------------------------------------------------------------------
-- Procedure		: SPV_AFFINEEXECUTION
-- Paramètre d'entrée	: @v_cyclique : Affinage cyclique ou non
--			  @v_iag_idagv : Identifiant AGV
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_PARAM : Absence procédure stockée d'affinage spécifique
--			    @CODE_KO_INCORRECT : Affinage incorrect
--			    @CODE_KO_SQL : Erreur SQL
--			    @CODE_KO_ADR_INCONNUE : Adresse inconnue
-- Descriptif		: Affinage d'une tâche à l'exécution
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_AFFINEEXECUTION]
	@v_cyclique bit,
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
	@v_status int,
	@v_retour int,
	@v_tac_idtache int,
	@v_tac_idmission int,
	@v_tac_position tinyint,
	@v_tac_idsystemeexecution bigint,
	@v_tac_idbaseexecution bigint,
	@v_tac_idsousbaseexecution bigint,
	@v_tac_idsystemeaffinage bigint,
	@v_tac_idbaseaffinage bigint,
	@v_tac_idsousbaseaffinage bigint,
	@v_tac_accesbase bit,
	@v_ord_idordre int,
	@v_ord_position int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_EXECUTION tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_STOPPE tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_RELANCE_MISSION tinyint,
	@DESC_AFFINAGE_ADRESSE tinyint,
	@DESC_AFFINAGE_TACHE tinyint,
	@DESC_ENVOYE tinyint

-- Déclaration des constantes de types d'actions
DECLARE
	@ACTI_PRIMAIRE bit

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_ATTENTE smallint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13
	SET @AFFI_EXECUTION = 2
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_STOPPE = 3
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_RELANCE_MISSION = 10
	SET @DESC_AFFINAGE_ADRESSE = 12
	SET @DESC_AFFINAGE_TACHE = 15
	SET @DESC_ENVOYE = 13
	SET @ACTI_PRIMAIRE = 0
	SET @ACTI_ATTENTE = 1

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	BEGIN TRAN
	-- Récupération des tâches à affiner
	IF @v_cyclique = 0
		DECLARE c_tache CURSOR LOCAL FOR SELECT ORD_IDORDRE, ORD_POSITION, A.TAC_IDTACHE, A.TAC_IDMISSION, A.TAC_POSITION_TACHE, A.TAC_IDADRSYS, A.TAC_IDADRBASE, A.TAC_IDADRSSBASE,
			A.TAC_IDAFFINAGEADRSYS, A.TAC_IDAFFINAGEADRBASE, A.TAC_IDAFFINAGEADRSSBASE, A.TAC_ACCES_BASE
			FROM ORDRE_AGV, TACHE A, ADRESSE WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE AND A.TAC_IDORDRE = ORD_IDORDRE
			AND A.TAC_POSITION_TACHE = (SELECT MIN(B.TAC_POSITION_TACHE) FROM TACHE B WHERE B.TAC_IDMISSION = A.TAC_IDMISSION
			AND B.TAC_IDETAT = @ETAT_ENATTENTE) AND A.TAC_AFFINAGEADR = @AFFI_EXECUTION AND ADR_SYSTEME = A.TAC_IDADRSYS AND ADR_BASE = A.TAC_IDADRBASE
			AND ADR_SOUSBASE = A.TAC_IDADRSSBASE AND ADR_TYPE = 0
	ELSE
		DECLARE c_tache CURSOR LOCAL FOR SELECT ORD_IDORDRE, ORD_POSITION, TAC_IDTACHE, TAC_IDMISSION, TAC_POSITION_TACHE, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE,
			TAC_IDAFFINAGEADRSYS, TAC_IDAFFINAGEADRBASE, TAC_IDAFFINAGEADRSSBASE, TAC_ACCES_BASE
			FROM ORDRE_AGV, TACHE, ADRESSE WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_STOPPE AND ORD_DSCETAT IN (@DESC_AFFINAGE_ADRESSE, @DESC_AFFINAGE_TACHE) AND TAC_IDORDRE = ORD_IDORDRE
			AND TAC_IDETAT = @ETAT_STOPPE AND TAC_DSCETAT IN (@DESC_AFFINAGE_ADRESSE, @DESC_AFFINAGE_TACHE) AND TAC_AFFINAGEADR = @AFFI_EXECUTION AND ADR_SYSTEME = TAC_IDADRSYS AND ADR_BASE = TAC_IDADRBASE
			AND ADR_SOUSBASE = TAC_IDADRSSBASE AND ADR_TYPE = 0
	OPEN c_tache
	FETCH NEXT FROM c_tache INTO @v_ord_idordre, @v_ord_position, @v_tac_idtache, @v_tac_idmission, @v_tac_position, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution,
		@v_tac_idsystemeaffinage, @v_tac_idbaseaffinage, @v_tac_idsousbaseaffinage, @v_tac_accesbase
	IF @@FETCH_STATUS = 0
	BEGIN
		WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
		BEGIN
			-- Evaluation de l'adresse d'affinage
			IF ((@v_tac_idsystemeaffinage IS NULL AND @v_tac_idbaseaffinage IS NULL AND @v_tac_idsousbaseaffinage IS NULL)
				OR EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv AND IAG_BASE_DEST = @v_tac_idbaseaffinage))
			BEGIN
				-- Appel de l'affinage spécifique
				EXEC @v_status = SPV_AFFINETACHE @v_iag_idagv, @v_tac_idtache, @AFFI_EXECUTION,
					@v_tac_idsystemeexecution out, @v_tac_idbaseexecution out, @v_tac_idsousbaseexecution out,
					@v_tac_idsystemeaffinage out, @v_tac_idbaseaffinage out, @v_tac_idsousbaseaffinage out, @v_tac_accesbase out
				SET @v_error = @@ERROR
				IF @v_status = @CODE_OK AND @v_error = 0
				BEGIN
					-- Mise à jour de la tâche
					UPDATE TACHE SET TAC_IDADRSYS = @v_tac_idsystemeexecution, TAC_IDADRBASE = @v_tac_idbaseexecution, TAC_IDADRSSBASE = @v_tac_idsousbaseexecution,
						TAC_IDAFFINAGEADRSYS = @v_tac_idsystemeaffinage, TAC_IDAFFINAGEADRBASE = @v_tac_idbaseaffinage, TAC_IDAFFINAGEADRSSBASE = @v_tac_idsousbaseaffinage,
						TAC_ACCES_BASE = @v_tac_accesbase WHERE TAC_IDTACHE = @v_tac_idtache
					SET @v_error = @@ERROR
				END
			END
			IF @v_status = @CODE_OK AND @v_error = 0
			BEGIN
				IF (@v_tac_idsystemeaffinage IS NOT NULL AND @v_tac_idbaseaffinage IS NOT NULL AND @v_tac_idsousbaseaffinage IS NOT NULL)
					AND NOT EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv AND IAG_BASE_DEST = @v_tac_idbaseaffinage)
				BEGIN
					-- L'adresse d'affinage n'est pas atteinte, insertion d'une tâche d'attente
					UPDATE TACHE SET TAC_POSITION_TACHE = TAC_POSITION_TACHE + 1 WHERE TAC_IDMISSION = @v_tac_idmission
						AND TAC_POSITION_TACHE >= @v_tac_position
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						INSERT INTO TACHE (TAC_IDMISSION, TAC_POSITION_TACHE, TAC_IDETAT, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE,
							TAC_OFSPROFONDEUR, TAC_OFSNIVEAU, TAC_OFSCOLONNE, TAC_NBACTION, TAC_AFFINAGEADR, TAC_IDAFFINAGEADRSYS, TAC_IDAFFINAGEADRBASE, TAC_IDAFFINAGEADRSSBASE,  TAC_ACCES_BASE)
							VALUES (@v_tac_idmission, @v_tac_position, @ETAT_ENATTENTE, @v_tac_idsystemeaffinage, @v_tac_idbaseaffinage, @v_tac_idsousbaseaffinage,
							NULL, NULL, NULL, 1, NULL, NULL, NULL, NULL, NULL)
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							SET @v_tac_idtache = SCOPE_IDENTITY()
							INSERT INTO ASSOCIATION_TACHE_ACTION_TACHE (ATA_IDTACHE, ATA_IDACTION, ATA_IDTYPEACTION, ATA_VALIDATION)
								VALUES (@v_tac_idtache, @ACTI_ATTENTE, @ACTI_PRIMAIRE, 0)
							SET @v_error = @@ERROR
							IF @v_error = 0
							BEGIN
								EXEC @v_status = SPV_CREATEORDRE @v_ord_position, @v_iag_idagv, @v_tac_idmission, @v_tac_position
								SET @v_error = @@ERROR
								IF @v_status = @CODE_OK AND @v_error = 0
									SET @v_retour = @CODE_OK
								ELSE
									SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
							END
							ELSE
								SET @v_retour = @CODE_KO_SQL
						END
						ELSE
							SET @v_retour = @CODE_KO_SQL
					END
					ELSE
						SET @v_retour = @CODE_KO_SQL
				END
				ELSE IF (@v_tac_idsystemeaffinage IS NOT NULL AND @v_tac_idbaseaffinage IS NOT NULL AND @v_tac_idsousbaseaffinage IS NOT NULL)
					AND EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv AND IAG_BASE_DEST = @v_tac_idbaseaffinage)
					SET @v_retour  = @CODE_KO_INCORRECT
				ELSE
					SET @v_retour = @CODE_OK
				IF @v_retour = @CODE_OK AND @v_cyclique = 1
				BEGIN
					EXEC @v_status = SPV_RELANCEORDRE @v_iag_idagv, @v_ord_idordre, @v_tac_idmission, @DESC_RELANCE_MISSION
					SET @v_error = @@ERROR
					IF @v_status IN (@CODE_KO, @CODE_OK) AND @v_error = 0
					BEGIN
						SET @v_status = @CODE_OK
						SET @v_retour = @CODE_OK
					END
					ELSE
						SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
				END
			END
			ELSE
				SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
			FETCH NEXT FROM c_tache INTO @v_ord_idordre, @v_ord_position, @v_tac_idtache, @v_tac_idmission, @v_tac_position, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution,
				@v_tac_idsystemeaffinage, @v_tac_idbaseaffinage, @v_tac_idsousbaseaffinage, @v_tac_accesbase
		END
	END
	ELSE
		SET @v_retour = @CODE_OK
	CLOSE c_tache
	DEALLOCATE c_tache
	IF @v_retour <> @CODE_OK
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	IF @v_retour <> @CODE_OK
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDAGV = @v_iag_idagv AND ((ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE) OR ORD_IDETAT = @ETAT_ENCOURS))
		BEGIN
			BEGIN TRAN
			-- L'affinage a échoué, interruption des ordres de l'AGV
			SET @v_error = 0
			SET @v_status = @CODE_KO
			SET @v_ord_idordre = NULL
			SELECT TOP 1 @v_ord_idordre = ORD_IDORDRE FROM ORDRE_AGV
				WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE AND (ORD_DSCETAT IS NULL OR ORD_DSCETAT <> @DESC_ENVOYE)
				ORDER BY ORD_POSITION
			EXEC @v_status = SPV_INTERROMPTORDRE @v_ord_idordre, @DESC_AFFINAGE_TACHE
			SET @v_error = @@ERROR
			IF NOT (@v_status = @CODE_OK AND @v_error = 0)
				ROLLBACK TRAN
			ELSE
				COMMIT TRAN
		END
	END
	RETURN @v_retour

