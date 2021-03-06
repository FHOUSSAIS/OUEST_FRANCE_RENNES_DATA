SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

CREATE PROCEDURE [dbo].[INT_ADDACTIONTACHE]
	@v_ata_idtache int,
	@v_ata_idaction int,
	@v_ata_idtypeaction tinyint,
	@v_ata_idoptionaction tinyint = NULL
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
	@v_retour int,
	@v_tac_idmission int,
	@v_mis_idetatmission tinyint,
	@v_mis_typemission tinyint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INTERDIT tinyint,
	@CODE_KO_ACTION_INCORRECTE_1 tinyint,
	@CODE_KO_ACTION_INCORRECTE_2 tinyint,
	@CODE_KO_ACTION_INCORRECTE_3 tinyint,
	@CODE_KO_ACTION_INCORRECTE_4 tinyint,
	@CODE_KO_ACTION_INCORRECTE_5 tinyint,
	@CODE_KO_ACTION_INCORRECTE_6 tinyint,
	@CODE_KO_ACTION_INCORRECTE_7 tinyint,
	@CODE_KO_ACTION_INCONNUE tinyint,
	@CODE_KO_MISSION_INCONNUE tinyint,
	@CODE_KO_ETAT_MISSION tinyint

-- Déclaration des constantes d'états
DECLARE
	@ETAT_ENATTENTE tinyint

-- Déclaration des constantes de types d'actions
DECLARE
	@ACTI_PRIMAIRE bit,
	@ACTI_SECONDAIRE bit

-- Déclaration des constantes d'actions
DECLARE
	@ACTI_INDEFINIE int,
	@ACTI_ATTENTE int,
	@ACTI_PRISE int,
	@ACTI_DEPOSE int,
	@ACTI_IDENTIFICATION int,
	@ACTI_PRESENCE int,
	@ACTI_CHARGEMENT_BATTERIE_PLAN int,
	@ACTI_CHANGEMENT_BATTERIE_MANUEL int,
	@ACTI_PESEE int,
	@ACTI_MAINTENANCE int,
	@ACTI_LONGUEUR int,
	@ACTI_LARGEUR int,
	@ACTI_HAUTEUR int,
	@ACTI_CHANGEMENT_BATTERIE_AUTOMATIQUE int,
	@ACTI_VIDANGE int,
	@ACTI_DEPOSE_BATTERIE int,
	@ACTI_PRISE_BATTERIE int,
	@ACTI_CHARGEMENT_BATTERIE_AUTO int
	
-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_INDEFINI tinyint,
	@TYPE_TRANSFERT tinyint,
	@TYPE_BATTERIE tinyint,
	@TYPE_MOUVEMENT tinyint,
	@TYPE_MAINTENANCE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCONNU = 7
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INTERDIT = 18
	SET @CODE_KO_ACTION_INCORRECTE_1 = 21
	SET @CODE_KO_ACTION_INCORRECTE_2 = 22
	SET @CODE_KO_ACTION_INCORRECTE_3 = 23
	SET @CODE_KO_ACTION_INCORRECTE_4 = 24
	SET @CODE_KO_ACTION_INCORRECTE_5 = 25
	SET @CODE_KO_ACTION_INCORRECTE_6 = 26
	SET @CODE_KO_ACTION_INCORRECTE_7 = 27
	SET @CODE_KO_ACTION_INCONNUE = 29
	SET @CODE_KO_MISSION_INCONNUE = 31
	SET @CODE_KO_ETAT_MISSION = 32
	SET @ETAT_ENATTENTE = 1
	SET @ACTI_PRIMAIRE = 0
	SET @ACTI_SECONDAIRE = 1
	SET @ACTI_INDEFINIE = 0
	SET @ACTI_ATTENTE = 1
	SET @ACTI_PRISE = 2
	SET @ACTI_DEPOSE = 4
	SET @ACTI_IDENTIFICATION = 8
	SET @ACTI_PRESENCE = 16
	SET @ACTI_CHARGEMENT_BATTERIE_PLAN = 32
	SET @ACTI_CHANGEMENT_BATTERIE_MANUEL = 64
	SET @ACTI_PESEE = 128
	SET @ACTI_MAINTENANCE = 256
	SET @ACTI_LONGUEUR = 512
	SET @ACTI_LARGEUR = 1024
	SET @ACTI_HAUTEUR = 2048
	SET @ACTI_CHANGEMENT_BATTERIE_AUTOMATIQUE = 4096
	SET @ACTI_VIDANGE = 8192
	SET @ACTI_PRISE_BATTERIE = 16384
	SET @ACTI_DEPOSE_BATTERIE = 32768
	SET @ACTI_CHARGEMENT_BATTERIE_AUTO = 65536
	SET @TYPE_INDEFINI = 0
	SET @TYPE_TRANSFERT = 1
	SET @TYPE_BATTERIE = 2
	SET @TYPE_MOUVEMENT = 3
	SET @TYPE_MAINTENANCE = 4

-- Initialisation des variables
	SET @v_transaction = 'ADDACTIONTACHE'
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @@TRANCOUNT > 0
		SET @v_local = 0
	ELSE
	BEGIN
		SET @v_local = 1
		BEGIN TRAN @v_transaction
	END
	-- Contrôle de l'existence de la tâche
	SELECT @v_tac_idmission = TAC_IDMISSION FROM INT_TACHE_MISSION WHERE TAC_IDTACHE = @v_ata_idtache
	IF @v_tac_idmission IS NOT NULL
	BEGIN
		-- Contrôle de l'existence de la mission
		SELECT @v_mis_idetatmission = MIS_IDETATMISSION, @v_mis_typemission = MIS_IDTYPEMISSION FROM INT_MISSION_VIVANTE WHERE MIS_IDMISSION = @v_tac_idmission
		IF @v_mis_idetatmission IS NOT NULL
		BEGIN
			-- Contrôle de l'état de la mission
			IF @v_mis_idetatmission = @ETAT_ENATTENTE
			BEGIN
				-- Contrôle de l'existence de l'action et de son option
				IF EXISTS (SELECT 1 FROM ACTION_TACHE WHERE ANT_IDACTION = @v_ata_idaction AND ANT_IDACTION <> @ACTI_INDEFINIE AND ANT_IDTYPEACTION = @v_ata_idtypeaction)
					AND (@v_ata_idoptionaction IS NULL OR (@v_ata_idoptionaction IS NOT NULL AND EXISTS (SELECT 1 FROM OPTION_ACTION WHERE OPA_ACTION = @v_ata_idaction AND OPA_ID = @v_ata_idoptionaction)))
				BEGIN
					-- Contrôle de l'unicité d'une action primaire dans la tâche
					IF ((@v_ata_idtypeaction = @ACTI_PRIMAIRE AND NOT EXISTS (SELECT 1 FROM INT_ACTION_TACHE WHERE ATA_IDTACHE = @v_ata_idtache
						AND ATA_IDTYPEACTION = @ACTI_PRIMAIRE)) OR (@v_ata_idtypeaction = @ACTI_SECONDAIRE))
					BEGIN
						-- Contrôle de l'unicité de l'action dans la tâche
						IF NOT EXISTS (SELECT 1 FROM INT_ACTION_TACHE WHERE ATA_IDTACHE = @v_ata_idtache AND ATA_IDACTION = @v_ata_idaction)
						BEGIN
							-- Contrôle de l'autorisation de création de mission de transfert de charge
							IF @v_ata_idaction IN (@ACTI_PRISE, @ACTI_DEPOSE, @ACTI_VIDANGE, @ACTI_IDENTIFICATION, @ACTI_PRESENCE, @ACTI_PESEE, @ACTI_LONGUEUR, @ACTI_LARGEUR, @ACTI_HAUTEUR)
								AND EXISTS (SELECT 1 FROM INT_PARAMETRE WHERE PAR_IDPARAMETRE = 'MISSION' AND PAR_VALEUR = 'FALSE')
								SET @v_error = @CODE_KO_INTERDIT
							IF @v_error = 0
							BEGIN
								-- Contrôle de la compatibilité des actions de la tâche
								-- Les actions de batterie ne sont compatibles qu'avec des actions d'attente
								IF @v_ata_idaction IN (@ACTI_CHARGEMENT_BATTERIE_PLAN, @ACTI_CHANGEMENT_BATTERIE_MANUEL, @ACTI_CHANGEMENT_BATTERIE_AUTOMATIQUE, @ACTI_DEPOSE_BATTERIE, @ACTI_PRISE_BATTERIE, @ACTI_CHARGEMENT_BATTERIE_AUTO)
									AND EXISTS (SELECT 1 FROM INT_ACTION_TACHE WHERE ATA_IDTACHE = @v_ata_idtache AND ATA_IDTYPEACTION = @ACTI_PRIMAIRE
									AND ATA_IDACTION <> @ACTI_ATTENTE)
									SET @v_error = @CODE_KO_ACTION_INCORRECTE_2
								-- Les actions de maintenance ne sont compatibles qu'avec des actions d'attente
								ELSE IF @v_ata_idaction = @ACTI_MAINTENANCE
									AND EXISTS (SELECT 1 FROM INT_ACTION_TACHE WHERE ATA_IDTACHE = @v_ata_idtache AND ATA_IDTYPEACTION = @ACTI_PRIMAIRE
									AND ATA_IDACTION <> @ACTI_ATTENTE)
									SET @v_error = @CODE_KO_ACTION_INCORRECTE_3
								-- Les actions de transfert de charge ne sont compatibles qu'avec des actions de transfert de charge
								ELSE IF @v_ata_idaction IN (@ACTI_PRISE, @ACTI_DEPOSE, @ACTI_VIDANGE)
									AND EXISTS (SELECT 1 FROM INT_ACTION_TACHE WHERE ATA_IDTACHE = @v_ata_idtache AND ATA_IDTYPEACTION = @ACTI_PRIMAIRE
									AND ATA_IDACTION IN (@ACTI_CHARGEMENT_BATTERIE_PLAN, @ACTI_CHANGEMENT_BATTERIE_MANUEL, @ACTI_CHANGEMENT_BATTERIE_AUTOMATIQUE,
									@ACTI_DEPOSE_BATTERIE, @ACTI_PRISE_BATTERIE, @ACTI_MAINTENANCE, @ACTI_CHARGEMENT_BATTERIE_AUTO))
									SET @v_error = @CODE_KO_ACTION_INCORRECTE_4
								-- Les actions de transfert de charge ne sont compatibles qu'avec des actions de transfert de charge
								ELSE IF @v_ata_idaction IN (@ACTI_IDENTIFICATION, @ACTI_PRESENCE, @ACTI_PESEE, @ACTI_LONGUEUR, @ACTI_LARGEUR, @ACTI_HAUTEUR)
									AND EXISTS (SELECT 1 FROM INT_ACTION_TACHE WHERE ATA_IDTACHE = @v_ata_idtache AND ATA_IDTYPEACTION = @ACTI_PRIMAIRE
									AND ATA_IDACTION IN (@ACTI_CHARGEMENT_BATTERIE_PLAN, @ACTI_CHANGEMENT_BATTERIE_MANUEL, @ACTI_CHANGEMENT_BATTERIE_AUTOMATIQUE,
									@ACTI_DEPOSE_BATTERIE, @ACTI_PRISE_BATTERIE, @ACTI_MAINTENANCE, @ACTI_CHARGEMENT_BATTERIE_AUTO))
									SET @v_error = @CODE_KO_ACTION_INCORRECTE_5
								IF @v_error = 0
								BEGIN
									-- Contrôle de la compatibilité des actions secondaires avec l'action primaire d'une tâche
									IF @v_ata_idtypeaction = @ACTI_SECONDAIRE AND EXISTS (SELECT 1 FROM INT_ACTION_TACHE WHERE ATA_IDTACHE = @v_ata_idtache
										AND ATA_IDACTION IN (@ACTI_ATTENTE, @ACTI_CHARGEMENT_BATTERIE_PLAN, @ACTI_CHANGEMENT_BATTERIE_MANUEL, @ACTI_CHANGEMENT_BATTERIE_AUTOMATIQUE,
										@ACTI_DEPOSE_BATTERIE, @ACTI_PRISE_BATTERIE, @ACTI_MAINTENANCE, @ACTI_CHARGEMENT_BATTERIE_AUTO))
										SET @v_error = @CODE_KO_ACTION_INCORRECTE_6
									IF @v_error = 0
									BEGIN
										INSERT INTO ASSOCIATION_TACHE_ACTION_TACHE (ATA_IDTACHE, ATA_IDACTION, ATA_IDTYPEACTION, ATA_VALIDATION, ATA_OPTION_ACTION)
											VALUES (@v_ata_idtache, @v_ata_idaction, @v_ata_idtypeaction, 0, @v_ata_idoptionaction)
										SET @v_error = @@ERROR
										IF @v_error = 0
										BEGIN
											UPDATE TACHE SET TAC_NBACTION = TAC_NBACTION + 1 WHERE TAC_IDTACHE = @v_ata_idtache
											SET @v_error = @@ERROR
											IF @v_error = 0
											BEGIN
												IF @v_mis_typemission IN (@TYPE_INDEFINI, @TYPE_MOUVEMENT)
												BEGIN
													-- Mise à jour du type de la mission
													UPDATE MISSION SET MIS_TYPEMISSION = CASE @v_ata_idaction WHEN @ACTI_ATTENTE THEN @TYPE_MOUVEMENT
														WHEN @ACTI_PRISE THEN @TYPE_TRANSFERT
														WHEN @ACTI_DEPOSE THEN @TYPE_TRANSFERT
														WHEN @ACTI_IDENTIFICATION THEN @TYPE_TRANSFERT
														WHEN @ACTI_PRESENCE THEN @TYPE_TRANSFERT
														WHEN @ACTI_CHARGEMENT_BATTERIE_PLAN THEN @TYPE_BATTERIE
														WHEN @ACTI_CHANGEMENT_BATTERIE_MANUEL THEN @TYPE_BATTERIE
														WHEN @ACTI_PESEE THEN @TYPE_TRANSFERT
														WHEN @ACTI_MAINTENANCE THEN @TYPE_MAINTENANCE
														WHEN @ACTI_LONGUEUR THEN @TYPE_TRANSFERT
														WHEN @ACTI_LARGEUR THEN @TYPE_TRANSFERT
														WHEN @ACTI_HAUTEUR THEN @TYPE_TRANSFERT
														WHEN @ACTI_CHANGEMENT_BATTERIE_AUTOMATIQUE THEN @TYPE_BATTERIE
														WHEN @ACTI_VIDANGE THEN @TYPE_TRANSFERT
														WHEN @ACTI_DEPOSE_BATTERIE THEN @TYPE_BATTERIE
														WHEN @ACTI_PRISE_BATTERIE THEN @TYPE_BATTERIE
														WHEN @ACTI_CHARGEMENT_BATTERIE_AUTO THEN @TYPE_BATTERIE
														ELSE MIS_TYPEMISSION END WHERE MIS_IDMISSION = @v_tac_idmission
													SET @v_error = @@ERROR
													IF @v_error = 0
														SET @v_retour = @CODE_OK
													ELSE
														SET @v_retour = @CODE_KO_SQL
												END
												ELSE
													SET @v_retour = @CODE_OK
											END
											ELSE
												SET @v_retour = @CODE_KO_SQL
										END
										ELSE
											SET @v_retour = @CODE_KO_SQL
									END
									ELSE
										SET @v_retour = @v_error
								END
								ELSE
									SET @v_retour = @v_error
							END
							ELSE
								SET @v_retour = @v_error
						END
						ELSE
							SET @v_retour = @CODE_KO_ACTION_INCORRECTE_7
					END
					ELSE
						SET @v_retour = @CODE_KO_ACTION_INCORRECTE_1
				END
				ELSE
					SET @v_retour = @CODE_KO_ACTION_INCONNUE
			END
			ELSE
				SET @v_retour = @CODE_KO_ETAT_MISSION
		END
		ELSE
			SET @v_retour = @CODE_KO_MISSION_INCONNUE
	END
	ELSE
		SET @v_retour = @CODE_KO_INCONNU
	IF @v_local = 1
	BEGIN
		IF @v_retour <> @CODE_OK
			ROLLBACK TRAN @v_transaction
		ELSE
			COMMIT TRAN @v_transaction
	END
	RETURN @v_retour


