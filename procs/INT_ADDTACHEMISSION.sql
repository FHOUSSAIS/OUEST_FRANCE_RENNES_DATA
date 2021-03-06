SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_ADDTACHEMISSION]
	@v_tac_idtache int out,
	@v_tac_idmission int,
	@v_tac_affinage tinyint = 0,
	@v_tac_idsystemeexecution bigint = NULL,
	@v_tac_idbaseexecution bigint = NULL,
	@v_tac_idsousbaseexecution bigint = NULL,
	@v_tac_idsystemeaffinage bigint = NULL,
	@v_tac_idbaseaffinage bigint = NULL,
	@v_tac_idsousbaseaffinage bigint = NULL,
	@v_tac_accesbase bit = NULL,
	@v_tac_idaction int,
	@v_tac_idoptionaction tinyint = NULL
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_local bit,
	@v_transaction varchar(32),
	@v_error int,
	@v_status int,
	@v_retour int,
	@v_mis_idetatmission tinyint,
	@v_chg_idcharge int,
	@v_tac_position tinyint,
	@v_cri_idcritere int,
	@v_bas_type_magasin tinyint,
	@v_bas_accumulation bit,
	@v_act_occupation smallint,
	@v_act_charge bit,
	@v_bas_type bit,
	@v_adr_type bit

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_VIDE tinyint,
	@CODE_KO_INCORRECT tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INCOMPATIBLE tinyint,
	@CODE_KO_ADR_INCONNUE tinyint,
	@CODE_KO_CRITERE_MISSION tinyint,
	@CODE_KO_MISSION_INCONNUE tinyint,
	@CODE_KO_ETAT_MISSION tinyint

-- Déclaration des constantes d'états
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint

-- Déclaration des constantes de familles
DECLARE
	@CRIT_MISSION tinyint

-- Déclaration des constantes de types de critères
DECLARE
	@TYPE_FIXE tinyint

-- Déclaration des constantes de types d'actions
DECLARE
	@ACTI_PRIMAIRE bit

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_AUCUN tinyint,
	@AFFI_ATTRIBUTION tinyint,
	@AFFI_EXECUTION tinyint

-- Déclaration des constantes de types de magasins
DECLARE
	@TYPE_INTERFACE tinyint,
	@TYPE_STOCK tinyint,
	@TYPE_PREPARATION tinyint,
	@TYPE_ENERGIE tinyint
	
-- Déclaration des constantes d'actions
DECLARE
	@ACTI_DEPOSE_BATTERIE int,
	@ACTI_PRISE_BATTERIE int
	
-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_VIDE = 10
	SET @CODE_KO_INCORRECT = 11
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INCOMPATIBLE = 14
	SET @CODE_KO_ADR_INCONNUE = 28
	SET @CODE_KO_CRITERE_MISSION = 30
	SET @CODE_KO_MISSION_INCONNUE = 31
	SET @CODE_KO_ETAT_MISSION = 32
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @CRIT_MISSION = 0
	SET @TYPE_FIXE = 0
	SET @ACTI_PRIMAIRE = 0
	SET @AFFI_AUCUN = 0
	SET @AFFI_ATTRIBUTION = 1
	SET @AFFI_EXECUTION = 2
	SET @TYPE_INTERFACE = 2
	SET @TYPE_STOCK = 3
	SET @TYPE_PREPARATION = 4
	SET @TYPE_ENERGIE = 6
	SET @ACTI_PRISE_BATTERIE = 16384
	SET @ACTI_DEPOSE_BATTERIE = 32768

-- Initialisation des variables
	SET @v_transaction = 'ADDTACHEMISSION'
	SET @v_error = 0
	SET @v_status = @CODE_KO
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la mission
	SELECT @v_mis_idetatmission = MIS_IDETATMISSION, @v_chg_idcharge = MIS_IDCHARGE FROM INT_MISSION_VIVANTE WHERE MIS_IDMISSION = @v_tac_idmission
	IF @v_mis_idetatmission IS NOT NULL
	BEGIN
		-- Contrôle de l'état de la mission
		IF @v_mis_idetatmission = @ETAT_ENATTENTE
		BEGIN
			-- Récupération des informations de l'action de la tâche
			SELECT @v_act_occupation = ACT_OCCUPATION, @v_act_charge = ACT_CHARGE FROM ACTION WHERE ACT_IDACTION = @v_tac_idaction
			-- Récupération de l'adresse de la charge
			IF @v_act_occupation = 1 AND @v_chg_idcharge IS NOT NULL AND (@v_tac_idsystemeexecution IS NULL OR @v_tac_idbaseexecution IS NULL OR @v_tac_idsousbaseexecution IS NULL)
				SELECT @v_tac_idsystemeexecution = CHG_IDSYSTEME, @v_tac_idbaseexecution = CHG_IDBASE, @v_tac_idsousbaseexecution = CHG_IDSOUSBASE
					FROM INT_CHARGE_VIVANTE WHERE CHG_IDCHARGE = @v_chg_idcharge
			-- Contrôle de l'existence de l'adresse
			SELECT @v_bas_type = ADR_TYPEBASE, @v_adr_type = ADR_TYPEADRESSE, @v_bas_type_magasin = ADR_IDTYPEMAGASIN, @v_bas_accumulation = ADR_ACCUMULATION
				FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_tac_idsystemeexecution AND ADR_IDBASE = @v_tac_idbaseexecution AND ADR_IDSOUSBASE = @v_tac_idsousbaseexecution
			-- Contrôle de l'existence de l'adresse
			IF @v_bas_type_magasin IS NOT NULL
			BEGIN
				-- Contrôle de la cohérence du type de base et de l'action de la tâche
				IF (((@v_act_charge = 1 AND @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION, @TYPE_INTERFACE)) OR (@v_act_charge = 0))
					AND ((@v_tac_idaction IN (@ACTI_DEPOSE_BATTERIE, @ACTI_PRISE_BATTERIE) AND @v_bas_type_magasin = @TYPE_ENERGIE) OR (@v_tac_idaction NOT IN (@ACTI_DEPOSE_BATTERIE, @ACTI_PRISE_BATTERIE))))
				BEGIN
					-- Récupération de la charge
					IF @v_act_occupation = 1 AND @v_chg_idcharge IS NULL AND @v_tac_affinage = @AFFI_AUCUN AND ((@v_bas_type_magasin = @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0))
					BEGIN
						SELECT @v_chg_idcharge = CHG_IDCHARGE FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_tac_idsystemeexecution AND CHG_IDBASE = @v_tac_idbaseexecution AND CHG_IDSOUSBASE = @v_tac_idsousbaseexecution
						IF @v_chg_idcharge IS NOT NULL AND NOT EXISTS (SELECT 1 FROM MISSION WHERE MIS_IDCHARGE = @v_chg_idcharge AND MIS_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE))
						BEGIN
							UPDATE MISSION SET MIS_IDCHARGE = @v_chg_idcharge WHERE MIS_IDMISSION = @v_tac_idmission
							SET @v_error = @@ERROR
						END
					END
					IF @v_error = 0
					BEGIN
						-- Contrôle de la cohérence de la charge et du type d'affinage
						IF ((@v_act_occupation = 1 AND ((@v_tac_affinage = @AFFI_AUCUN AND ((@v_chg_idcharge IS NULL AND @v_bas_type_magasin IN (@TYPE_STOCK, @TYPE_PREPARATION) AND @v_bas_accumulation = 1)
							OR (@v_chg_idcharge IS NOT NULL AND ((@v_bas_type_magasin = @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0))
							AND EXISTS (SELECT 1 FROM INT_CHARGE_VIVANTE WHERE CHG_IDSYSTEME = @v_tac_idsystemeexecution AND CHG_IDBASE = @v_tac_idbaseexecution AND CHG_IDSOUSBASE = @v_tac_idsousbaseexecution))))
							OR (@v_tac_affinage IN (@AFFI_ATTRIBUTION, @AFFI_EXECUTION))))
							OR (@v_act_occupation <> 1))
						BEGIN
							-- Contrôle de la cohérence du type de base et du type d'affinage
							IF ((@v_tac_affinage = @AFFI_AUCUN AND @v_bas_type = 1 AND (@v_adr_type = 1 OR @v_act_occupation <> 1))
								OR (@v_tac_affinage = @AFFI_ATTRIBUTION)
								OR (@v_tac_affinage = @AFFI_EXECUTION AND ((@v_tac_idsystemeaffinage IS NULL AND @v_tac_idbaseaffinage IS NULL AND @v_tac_idsousbaseaffinage IS NULL)
								OR EXISTS (SELECT 1 FROM INT_ADRESSE WHERE ADR_IDSYSTEME = @v_tac_idsystemeaffinage AND ADR_IDBASE = @v_tac_idbaseaffinage
								AND ADR_IDSOUSBASE = @v_tac_idsousbaseaffinage AND ADR_TYPEBASE = 1))))
							BEGIN
								IF @v_tac_affinage <> @AFFI_AUCUN AND @v_adr_type = 1
									SET @v_tac_affinage = @AFFI_AUCUN
								SELECT @v_tac_position = ISNULL(MAX(TAC_POSITION), 0) + 1 FROM INT_TACHE_MISSION WHERE TAC_IDMISSION = @v_tac_idmission
								IF @v_tac_affinage = @AFFI_AUCUN
									INSERT INTO TACHE (TAC_IDMISSION, TAC_POSITION_TACHE, TAC_IDETAT, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE,
										TAC_OFSPROFONDEUR, TAC_OFSNIVEAU, TAC_OFSCOLONNE, TAC_NBACTION, TAC_AFFINAGEADR, TAC_IDAFFINAGEADRSYS, TAC_IDAFFINAGEADRBASE, TAC_IDAFFINAGEADRSSBASE, TAC_ACCES_BASE)
										VALUES (@v_tac_idmission, @v_tac_position, @ETAT_ENATTENTE, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution,
										NULL, NULL, NULL, 0, @v_tac_affinage, NULL, NULL, NULL, @v_tac_accesbase)
								ELSE IF @v_tac_affinage = @AFFI_ATTRIBUTION
									INSERT INTO TACHE (TAC_IDMISSION, TAC_POSITION_TACHE, TAC_IDETAT, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE,
										TAC_OFSPROFONDEUR, TAC_OFSNIVEAU, TAC_OFSCOLONNE, TAC_NBACTION, TAC_AFFINAGEADR, TAC_IDAFFINAGEADRSYS, TAC_IDAFFINAGEADRBASE, TAC_IDAFFINAGEADRSSBASE, TAC_ACCES_BASE)
										VALUES (@v_tac_idmission, @v_tac_position, @ETAT_ENATTENTE, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution,
										NULL, NULL, NULL, 0, @v_tac_affinage, NULL, NULL, NULL, @v_tac_accesbase)
								ELSE IF @v_tac_affinage = @AFFI_EXECUTION
									INSERT INTO TACHE (TAC_IDMISSION, TAC_POSITION_TACHE, TAC_IDETAT, TAC_IDADRSYS, TAC_IDADRBASE, TAC_IDADRSSBASE,
										TAC_OFSPROFONDEUR, TAC_OFSNIVEAU, TAC_OFSCOLONNE, TAC_NBACTION, TAC_AFFINAGEADR, TAC_IDAFFINAGEADRSYS, TAC_IDAFFINAGEADRBASE, TAC_IDAFFINAGEADRSSBASE, TAC_ACCES_BASE)
										VALUES (@v_tac_idmission, @v_tac_position, @ETAT_ENATTENTE, @v_tac_idsystemeexecution, @v_tac_idbaseexecution, @v_tac_idsousbaseexecution,
										NULL, NULL, NULL, 0, @v_tac_affinage, @v_tac_idsystemeaffinage, @v_tac_idbaseaffinage, @v_tac_idsousbaseaffinage, @v_tac_accesbase)
								SET @v_error = @@ERROR
								IF @v_error = 0
								BEGIN
									SET @v_tac_idtache = SCOPE_IDENTITY()
									-- Ajout de l'action à la tâche
									EXEC @v_status = INT_ADDACTIONTACHE @v_tac_idtache, @v_tac_idaction, @ACTI_PRIMAIRE, @v_tac_idoptionaction
									SET @v_error = @@ERROR
									IF @v_status = @CODE_OK AND @v_error = 0
									BEGIN
										DECLARE c_critere CURSOR LOCAL FAST_FORWARD FOR SELECT CRI_IDCRITERE FROM CRITERE WHERE CRI_FAMILLE = @CRIT_MISSION
											AND CRI_CHAMP IS NULL AND CRI_IDTYPE = @TYPE_FIXE
										OPEN c_critere
										FETCH NEXT FROM c_critere INTO @v_cri_idcritere
										WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
										BEGIN
											EXEC @v_status = SPV_SETCRITEREFIXEMISSION @v_cri_idcritere, @v_tac_idmission, NULL
											SET @v_error = @@ERROR
											FETCH NEXT FROM c_critere INTO @v_cri_idcritere
										END
										CLOSE c_critere
										DEALLOCATE c_critere
										IF @v_status = @CODE_OK AND @v_error = 0
											SET @v_retour = @CODE_OK
										ELSE
											SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
									END
									ELSE
										SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
								END
								ELSE
									SET @v_retour = @CODE_KO_SQL
							END
							ELSE
								SET @v_retour = @CODE_KO_INCORRECT
						END
						ELSE
						BEGIN
							IF @v_chg_idcharge IS NULL AND ((@v_bas_type_magasin = @TYPE_INTERFACE) OR (@v_bas_type_magasin = @TYPE_STOCK AND @v_bas_accumulation = 0))
								SET @v_retour = @CODE_KO_VIDE
							ELSE
								SET @v_retour = @CODE_KO_INCORRECT
						END
					END
					ELSE
						SET @v_retour = @CODE_KO_SQL
				END
				ELSE
					SET @v_retour = @CODE_KO_INCOMPATIBLE
			END
			ELSE
				SET @v_retour = @CODE_KO_ADR_INCONNUE
		END
		ELSE
			SET @v_retour = @CODE_KO_ETAT_MISSION
	END
	ELSE
		SET @v_retour = @CODE_KO_MISSION_INCONNUE
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour

