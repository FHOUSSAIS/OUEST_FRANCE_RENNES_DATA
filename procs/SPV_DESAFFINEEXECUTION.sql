SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF








-----------------------------------------------------------------------------------------
-- Procedure		: SPV_DESAFFINEEXECUTION
-- Paramètre d'entrée	: @v_mis_idmission : Identifiant mission
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_SQL : Erreur SQL
-- Descriptif		: Désaffinage d'une mission à l'exécution
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_DESAFFINEEXECUTION]
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
	@v_retour int,
	@v_mis_idetatmission tinyint,
	@v_mis_idcharge int,
	@v_tac_idtache int,
	@v_tac_affinage tinyint,
	@v_tac_idsystemeexecution bigint,
	@v_tac_idbaseexecution bigint,
	@v_tac_idsousbaseexecution bigint,
	@v_tac_idsystemeaffinage bigint,
	@v_tac_idbaseaffinage bigint,
	@v_tac_idsousbaseaffinage bigint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_ATTRIBUTION tinyint,
	@AFFI_EXECUTION tinyint
	
-- Déclaration des constantes de traces
DECLARE
	@TRAC_CREATION tinyint,
	@TRAC_AFFINAGE tinyint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_STOPPE tinyint,	
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_ENVOYE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @AFFI_ATTRIBUTION = 1
	SET @AFFI_EXECUTION = 2
	SET @TRAC_CREATION = 1
	SET @TRAC_AFFINAGE = 20
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_STOPPE = 3
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_ENVOYE = 13

-- Initialisation des variables
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	-- Récupération de l'état de la mission
	SELECT @v_mis_idetatmission = MIS_IDETAT FROM MISSION WHERE MIS_IDMISSION = @v_mis_idmission
	IF @v_mis_idetatmission = @ETAT_ENATTENTE
	BEGIN
		-- Réinitialisation de l'identifiant de la charge
		SELECT TOP 1 @v_mis_idcharge = TMI_IDCHARGE FROM TRACE_MISSION WHERE TMI_IDMISSION = @v_mis_idmission AND TMI_TYPETRC = @TRAC_CREATION ORDER BY TMI_ID
		UPDATE MISSION SET MIS_IDCHARGE = @v_mis_idcharge WHERE MIS_IDMISSION = @v_mis_idmission
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			DECLARE c_tache CURSOR LOCAL FOR SELECT TAC_IDTACHE, TAC_AFFINAGEADR, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE FROM TACHE
				WHERE TAC_IDMISSION = @v_mis_idmission
				FOR UPDATE
			OPEN c_tache
			FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_affinage, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				-- Mise à jour des tâches liées aux charges sur des bases d'accumulation
				IF EXISTS (SELECT 1 FROM ASSOCIATION_TACHE_ACTION_TACHE, ACTION, ADRESSE, BASE WHERE ATA_IDTACHE = @v_tac_idtache
					AND ACT_IDACTION = ATA_IDACTION AND ACT_CHARGE = 1 AND ADR_SYSTEME = @v_tac_idsystemeexecution AND ADR_BASE = @v_tac_idbaseexecution
					AND ADR_SOUSBASE = @v_tac_idsousbaseexecution AND ADR_TYPE = 1 AND BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE
					AND BAS_TYPE_MAGASIN IN (@TYPE_STOCK, @TYPE_PREPARATION) AND BAS_ACCUMULATION = 1)
				BEGIN
					UPDATE TACHE SET TAC_OFSPROFONDEUR = NULL, TAC_OFSNIVEAU = NULL, TAC_OFSCOLONNE = NULL WHERE CURRENT OF c_tache
					SET @v_error = @@ERROR
				END
				-- Mise à jour des tâches affinées à l'attribution ou à l'exécution
				IF @v_error = 0 AND @v_tac_affinage IN (@AFFI_ATTRIBUTION, @AFFI_EXECUTION)
				BEGIN
					SET @v_tac_idsystemeexecution = NULL
					SET @v_tac_idbaseexecution = NULL
					SET @v_tac_idsousbaseexecution = NULL
					SET @v_tac_idsystemeaffinage = NULL
					SET @v_tac_idbaseaffinage = NULL
					SET @v_tac_idsousbaseaffinage = NULL
					SELECT TOP 1 @v_tac_idsystemeexecution = TMI_ADRSYS, @v_tac_idbaseexecution = TMI_ADRBASE, @v_tac_idsousbaseexecution = TMI_ADRSSBASE,
						@v_tac_idsystemeaffinage = TMI_AFFINAGEADRSYS, @v_tac_idbaseaffinage = TMI_AFFINAGEADRBASE, @v_tac_idsousbaseaffinage = TMI_AFFINAGEADRSSBASE
						FROM TRACE_MISSION WHERE TMI_IDMISSION = @v_mis_idmission AND TMI_IDTACHE = @v_tac_idtache AND TMI_TYPETRC = @TRAC_AFFINAGE
						ORDER BY TMI_ID
					IF @v_tac_idsystemeexecution IS NOT NULL AND @v_tac_idbaseexecution IS NOT NULL AND @v_tac_idsousbaseexecution IS NOT NULL
					BEGIN
						IF @v_tac_affinage = @AFFI_ATTRIBUTION
							UPDATE TACHE SET TAC_IDADRSYS = @v_tac_idsystemeexecution, TAC_IDADRBASE = @v_tac_idbaseexecution, TAC_IDADRSSBASE = @v_tac_idsousbaseexecution
								WHERE CURRENT OF c_tache
						ELSE
							UPDATE TACHE SET TAC_IDADRSYS = @v_tac_idsystemeexecution, TAC_IDADRBASE = @v_tac_idbaseexecution, TAC_IDADRSSBASE = @v_tac_idsousbaseexecution,
								TAC_IDAFFINAGEADRSYS = @v_tac_idsystemeaffinage, TAC_IDAFFINAGEADRBASE = @v_tac_idbaseaffinage, TAC_IDAFFINAGEADRSSBASE = @v_tac_idsousbaseaffinage
								WHERE CURRENT OF c_tache
					END
					SET @v_error = @@ERROR
				END
				FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_affinage, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution
			END
			CLOSE c_tache
			DEALLOCATE c_tache
			IF @v_error = 0
			BEGIN
				-- Suppression des tâches insérées à l'exécution lors d'affinages successifs
				DELETE ASSOCIATION_TACHE_ACTION_TACHE WHERE ATA_IDTACHE IN (SELECT TAC_IDTACHE FROM TACHE WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_AFFINAGEADR IS NULL)
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					DELETE TACHE FROM TACHE WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_AFFINAGEADR IS NULL
					SET @v_error = @@ERROR
					IF @v_error = 0
					BEGIN
						-- Mise à jour de la position des tâches
						UPDATE TACHE SET TAC_POSITION_TACHE = (SELECT COUNT(*) + 1 FROM TACHE B WHERE B.TAC_IDMISSION = A.TAC_IDMISSION AND B.TAC_POSITION_TACHE < A.TAC_POSITION_TACHE)
							FROM TACHE A WHERE TAC_IDMISSION = @v_mis_idmission
						SET @v_error = @@ERROR
						IF @v_error = 0
							SET @v_retour = @CODE_OK
						ELSE
							SET @v_retour = @CODE_KO_SQL
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
		ELSE
			SET @v_retour = @CODE_KO_SQL
	END
	ELSE IF @v_mis_idetatmission = @ETAT_STOPPE
	BEGIN
		DECLARE c_tache CURSOR LOCAL FOR SELECT TAC_IDTACHE, TAC_AFFINAGEADR, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE FROM TACHE
			LEFT OUTER JOIN ORDRE_AGV ON ORD_IDORDRE = TAC_IDORDRE
			WHERE TAC_IDMISSION = @v_mis_idmission AND TAC_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
			AND ((ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE) OR ORD_IDETAT = @ETAT_ENCOURS)
			FOR UPDATE
		OPEN c_tache
		FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_affinage, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution
		WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
		BEGIN
			-- Mise à jour des tâches liées aux charges sur des bases d'accumulation
			IF EXISTS (SELECT 1 FROM ASSOCIATION_TACHE_ACTION_TACHE, ACTION, ADRESSE, BASE WHERE ATA_IDTACHE = @v_tac_idtache
				AND ACT_IDACTION = ATA_IDACTION AND ACT_CHARGE = 1 AND ADR_SYSTEME = @v_tac_idsystemeexecution AND ADR_BASE = @v_tac_idbaseexecution
				AND ADR_SOUSBASE = @v_tac_idsousbaseexecution AND ADR_TYPE = 1 AND BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE
				AND BAS_TYPE_MAGASIN IN (@TYPE_STOCK, @TYPE_PREPARATION) AND BAS_ACCUMULATION = 1)
			BEGIN
				UPDATE TACHE SET TAC_OFSPROFONDEUR = NULL, TAC_OFSNIVEAU = NULL, TAC_OFSCOLONNE = NULL WHERE CURRENT OF c_tache
				SET @v_error = @@ERROR
			END
			-- Mise à jour des tâches affinées à l'exécution
			IF @v_error = 0 AND @v_tac_affinage = @AFFI_EXECUTION
			BEGIN
				SET @v_tac_idsystemeexecution = NULL
				SET @v_tac_idbaseexecution = NULL
				SET @v_tac_idsousbaseexecution = NULL
				SET @v_tac_idsystemeaffinage = NULL
				SET	@v_tac_idbaseaffinage = NULL
				SET @v_tac_idsousbaseaffinage = NULL
				-- Récupération des adresses d'exécution et d'affinage
				SELECT TOP 1 @v_tac_idsystemeexecution = TMI_ADRSYS, @v_tac_idbaseexecution = TMI_ADRBASE, @v_tac_idsousbaseexecution = TMI_ADRSSBASE,
					@v_tac_idsystemeaffinage = TMI_AFFINAGEADRSYS, @v_tac_idbaseaffinage = TMI_AFFINAGEADRBASE, @v_tac_idsousbaseaffinage = TMI_AFFINAGEADRSSBASE
					FROM TRACE_MISSION WHERE TMI_IDMISSION = @v_mis_idmission AND TMI_IDTACHE = @v_tac_idtache AND TMI_TYPETRC = @TRAC_AFFINAGE
					ORDER BY TMI_ID DESC
				IF @v_tac_idsystemeexecution IS NOT NULL AND @v_tac_idbaseexecution IS NOT NULL AND @v_tac_idsousbaseexecution IS NOT NULL
				BEGIN
					UPDATE TACHE SET TAC_IDADRSYS = @v_tac_idsystemeexecution, TAC_IDADRBASE = @v_tac_idbaseexecution, TAC_IDADRSSBASE = @v_tac_idsousbaseexecution,
						TAC_IDAFFINAGEADRSYS = @v_tac_idsystemeaffinage, TAC_IDAFFINAGEADRBASE = @v_tac_idbaseaffinage, TAC_IDAFFINAGEADRSSBASE = @v_tac_idsousbaseaffinage
						WHERE CURRENT OF c_tache
					SET @v_error = @@ERROR
				END
			END
			SET @v_error = @@ERROR
			FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_affinage, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution
		END
		CLOSE c_tache
		DEALLOCATE c_tache
		IF @v_error = 0
			SET @v_retour = @CODE_OK
		ELSE
			SET @v_retour = @CODE_KO_SQL
	END
	RETURN @v_retour

