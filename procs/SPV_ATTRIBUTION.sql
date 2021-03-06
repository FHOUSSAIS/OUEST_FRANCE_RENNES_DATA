SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_ATTRIBUTION
-- Paramètre d'entrée	: @v_idAgv : Identifiant de l'Agv auquel on attribue la mission
--			  @v_idMission : Identifiant de la mission à attribuer
--			  @v_lstBase : chaîne de caractères listant la fusion ordonnée 
--			  des bases des ordres Agv et des bases de la mission à attribuer. 
--			  @v_debutAction : Indique s'il s'agit d'une attribution suite à l'événement début action
-- Paramètre de sortie	: Code de retour pra défaut:
--			  - @CODE_OK :la mission a été corerectement attribuée à l'Agv.
--			  - @CODE_KO_SQL: Une erreur s'est produite lors de l'attribution. 
--			  - @CODE_KO_INCOMPATIBLE : La mission n'est pas compatible avec les capacités physiques des outils
-- Descriptif		: Cette procédure attribue une mission à un agv.
--			  c'est à dire calcule les nouveaux ordres Agv à partir des tâches
--			  de la mission et intègre ces ordres dans la liste existantes des
--			  ordres Agv.
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_ATTRIBUTION]
	@v_idAgv tinyint,
	@v_idMission integer,
	@v_lstBase varchar(8000),
	@v_debutAction bit
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
	@v_charindex int,
	@v_association bit,
	@v_ord_idordre int,
	@v_ord_position int,
	@v_ord_idetat tinyint,
	@v_tac_idtache int,
	@v_tac_position int,
	@v_tac_affinage tinyint,
	@v_baseCourante bigint,
	@v_baseOrdreCourant bigint,
	@v_baseOrdreSuivant bigint,
	@v_baseTache bigint,
	@v_occupationOrdreCourant smallint,
	@v_occupationTache smallint,
	@v_ord_action bit

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENCOURS tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_EXECUTION tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @ETAT_ENCOURS = 2
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @AFFI_EXECUTION = 2

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO
	SET @v_association = 0

	BEGIN TRAN
	IF EXISTS (SELECT 1 FROM MISSION WHERE MIS_IDMISSION = @v_idMission)
	BEGIN
		IF @v_debutAction = 1
			SELECT @v_ord_position = ORD_POSITION + 1 FROM ORDRE_AGV WHERE ORD_IDETAT = @ETAT_ENCOURS AND ORD_IDAGV = @v_idAgv
		SELECT TOP 1 @v_ord_idordre = A.ORD_IDORDRE, @v_ord_position = A.ORD_POSITION, @v_ord_idetat = A.ORD_IDETAT, @v_baseOrdreCourant = TAC_IDADRBASE,
			@v_occupationOrdreCourant = ACT_OCCUPATION, @v_ord_action = ACT_ACTION,
			@v_baseOrdreSuivant = (SELECT TOP 1 (SELECT TOP 1 TAC_IDADRBASE FROM TACHE WHERE TAC_IDORDRE = B.ORD_IDORDRE)
			FROM ORDRE_AGV B WHERE B.ORD_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE) AND B.ORD_IDAGV = @v_idAgv
			AND B.ORD_POSITION > A.ORD_POSITION ORDER BY B.ORD_POSITION)
			FROM ORDRE_AGV A INNER JOIN (SELECT TAC_IDORDRE, TAC_IDADRBASE, ACT_OCCUPATION, ACT_ACTION FROM TACHE INNER JOIN ASSOCIATION_TACHE_ACTION_TACHE ON ATA_IDTACHE = TAC_IDTACHE INNER JOIN ACTION ON ACT_IDACTION = ATA_IDACTION WHERE ATA_IDTYPEACTION = 0) TACHE ON TAC_IDORDRE = A.ORD_IDORDRE
			WHERE A.ORD_IDAGV = @v_idAgv AND A.ORD_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE) AND (@v_debutAction = 0 OR A.ORD_IDETAT <> @ETAT_ENCOURS)
			ORDER BY A.ORD_POSITION
		SELECT TOP 1 @v_tac_idtache = TAC_IDTACHE, @v_tac_position = TAC_POSITION_TACHE, @v_tac_affinage = TAC_AFFINAGEADR, @v_baseTache = TAC_IDADRBASE, @v_occupationTache = (SELECT ACT_OCCUPATION FROM ASSOCIATION_TACHE_ACTION_TACHE INNER JOIN ACTION ON ACT_IDACTION = ATA_IDACTION WHERE ATA_IDTACHE = TAC_IDTACHE AND ATA_IDTYPEACTION = 0)
			FROM TACHE WHERE TAC_IDMISSION = @v_idMission ORDER BY TAC_POSITION_TACHE
		SET @v_charindex = CHARINDEX(';', @v_lstBase)
		IF @v_charindex <> 0
		BEGIN
			-- Récupération de la base courante dans la liste de bases
			SET @v_baseCourante = CONVERT(bigint, SUBSTRING(@v_lstBase, 1, @v_charindex - 1))
			SET @v_lstBase = SUBSTRING(@v_lstBase, @v_charindex + 1, LEN(@v_lstBase) - @v_charindex)
			WHILE ((@v_charindex <> 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
			BEGIN
				IF @v_baseOrdreCourant IS NULL
					SELECT TOP 1 @v_ord_idordre = A.ORD_IDORDRE, @v_ord_position = A.ORD_POSITION, @v_ord_idetat = A.ORD_IDETAT, @v_baseOrdreCourant = TAC_IDADRBASE,
						@v_occupationOrdreCourant = ACT_OCCUPATION, @v_ord_action = ACT_ACTION,
						@v_baseOrdreSuivant = (SELECT TOP 1 (SELECT TOP 1 TAC_IDADRBASE FROM TACHE WHERE TAC_IDORDRE = B.ORD_IDORDRE)
						FROM ORDRE_AGV B WHERE B.ORD_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE) AND B.ORD_IDAGV = @v_idAgv
						AND B.ORD_POSITION > A.ORD_POSITION ORDER BY B.ORD_POSITION)
						FROM ORDRE_AGV A INNER JOIN (SELECT TAC_IDORDRE, TAC_IDADRBASE, ACT_OCCUPATION, ACT_ACTION FROM TACHE INNER JOIN ASSOCIATION_TACHE_ACTION_TACHE ON ATA_IDTACHE = TAC_IDTACHE INNER JOIN ACTION ON ACT_IDACTION = ATA_IDACTION WHERE ATA_IDTYPEACTION = 0) TACHE ON TAC_IDORDRE = A.ORD_IDORDRE
						WHERE A.ORD_IDAGV = @v_idAgv AND A.ORD_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE) AND (@v_debutAction = 0 OR A.ORD_IDETAT <> @ETAT_ENCOURS)
						AND ((@v_ord_idordre IS NULL AND A.ORD_POSITION >= @v_ord_position) OR (@v_ord_idordre IS NOT NULL AND A.ORD_POSITION > @v_ord_position))
						ORDER BY A.ORD_POSITION
				IF @v_baseTache IS NULL
					SELECT TOP 1 @v_tac_idtache = TAC_IDTACHE, @v_tac_position = TAC_POSITION_TACHE, @v_tac_affinage = TAC_AFFINAGEADR, @v_baseTache = TAC_IDADRBASE, @v_occupationTache = (SELECT ACT_OCCUPATION FROM ASSOCIATION_TACHE_ACTION_TACHE INNER JOIN ACTION ON ACT_IDACTION = ATA_IDACTION WHERE ATA_IDTACHE = TAC_IDTACHE AND ATA_IDTYPEACTION = 0)
						FROM TACHE WHERE TAC_IDMISSION = @v_idMission AND TAC_POSITION_TACHE > @v_tac_position
						ORDER BY TAC_POSITION_TACHE
				IF @v_baseCourante = @v_baseOrdreCourant AND @v_baseOrdreCourant IS NOT NULL AND @v_association = 0
					SET @v_association = 1
				ELSE IF @v_baseCourante = @v_baseTache AND @v_baseTache IS NOT NULL
				BEGIN
					IF @v_baseCourante = @v_baseOrdreCourant AND @v_baseOrdreCourant IS NOT NULL
					BEGIN
						-- Vérification que le nombre d'actions de la tâche mission est égal au nombre d'actions de l'ordre courant
						-- Recherche de l'existence d'une action de la tâche mission différente des actions de 
						-- l'ordre courant.
						-- Contrôle de l'affinage de la tâche
						IF (@v_tac_affinage = @AFFI_EXECUTION)
							OR EXISTS (SELECT 1 FROM TACHE TACHEMISSION, ASSOCIATION_TACHE_ACTION_TACHE ACTIONTACHE
							WHERE TACHEMISSION.TAC_IDTACHE = @v_tac_idtache
							AND ACTIONTACHE.ATA_IDTACHE = TACHEMISSION.TAC_IDTACHE
							AND NOT EXISTS (SELECT 1 FROM TACHE TACHEORDRE, ASSOCIATION_TACHE_ACTION_TACHE ACTIONORDRE
							WHERE TACHEORDRE.TAC_IDORDRE = @v_ord_idordre
							AND ACTIONORDRE.ATA_IDTACHE = TACHEORDRE.TAC_IDTACHE
							AND ACTIONTACHE.ATA_IDACTION = ACTIONORDRE.ATA_IDACTION AND ACTIONTACHE.ATA_IDTYPEACTION = ACTIONORDRE.ATA_IDTYPEACTION
							AND ISNULL(ACTIONTACHE.ATA_OPTION_ACTION, 0) = ISNULL(ACTIONORDRE.ATA_OPTION_ACTION, 0)
							AND TACHEMISSION.TAC_NBACTION = TACHEORDRE.TAC_NBACTION))
						BEGIN
							IF ((@v_baseCourante <> @v_baseOrdreSuivant AND @v_baseOrdreSuivant IS NOT NULL) OR (@v_baseOrdreSuivant IS NULL))
							BEGIN
								-- La tâche a une action différente de celle de l'ordre courant
								-- ou elle fait l'objet d'un affinage à l'exécution
								-- => Elle donne lieu à un nouvel ordre
								IF @v_occupationOrdreCourant = -1 AND @v_occupationTache = 1 AND @v_ord_idetat <> @ETAT_ENCOURS
									SET @v_ord_position = ISNULL(@v_ord_position, 0)
								ELSE
									SET @v_ord_position = ISNULL(@v_ord_position, 0) + 1
								EXEC @v_status = SPV_CREATEORDRE @v_ord_position, @v_idAgv, @v_idMission, @v_tac_position
								SET @v_error = @@ERROR
								IF NOT (@v_status = @CODE_OK AND @v_error = 0)
									SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
								ELSE IF @v_occupationOrdreCourant = -1 AND @v_occupationTache = 1 AND @v_ord_idetat <> @ETAT_ENCOURS
									SET @v_ord_position = ISNULL(@v_ord_position, 0) + 1
								SET @v_ord_idordre = NULL
								SET @v_baseOrdreCourant = NULL
								SET @v_association = 1
							END
							ELSE
							BEGIN
								SET @v_baseOrdreCourant = NULL
								SET @v_association = 0
								CONTINUE
							END
						END
						ELSE
						BEGIN
							-- Les actions de la tâche mission sont identiques à celles de l'ordre courant
							-- => On la rattache donc à l'ordre courant
							-- => Si l'ordre est en cours, la tâche passe en cours
							-- Si l'ordre est en cours, on ne peut le modifier seulement s'il sera suivi d'une action permettant ainsi de renvoyer les nouvelles informations à TrafficControl
							IF @v_ord_idetat = @ETAT_ENCOURS AND @v_ord_action = 1
							BEGIN
		        				UPDATE TACHE SET TAC_IDORDRE = @v_ord_idordre, TAC_IDETAT = @v_ord_idetat, TAC_DSCETAT = NULL WHERE TAC_IDTACHE = @v_tac_idtache
		        				SET @v_error = @@ERROR
		        				IF @v_error = 0
		        				BEGIN
									-- Recherche des adresses à affiner
									EXEC @v_status = SPV_AFFINEADRESSE 0, @v_idAgv, @v_ord_idordre
									SET @v_error = @@ERROR
									IF NOT (@v_status = @CODE_OK AND @v_error = 0)
										SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
								END
			        		END
							ELSE
							BEGIN
								UPDATE TACHE set TAC_IdOrdre = @v_ord_idordre WHERE TAC_IDTACHE = @v_tac_idtache
								SET @v_error = @@ERROR
								IF @v_error <> 0
									SET @v_retour = @CODE_KO_SQL
							END
						END
						SET @v_baseTache = NULL
					END
                    ELSE IF ((@v_baseCourante <> @v_baseOrdreSuivant AND @v_baseOrdreSuivant IS NOT NULL) OR (@v_baseOrdreSuivant IS NULL))
					BEGIN
						-- La base courante ne correspond pas à la base de l'ordre courant
						-- => Elle donne lieu à un nouvel ordre
						SET @v_ord_position = CASE @v_association WHEN 1 THEN ISNULL(@v_ord_position, 0) + 1 ELSE ISNULL(@v_ord_position, 0) END
						EXEC @v_status = SPV_CREATEORDRE @v_ord_position, @v_idAgv, @v_idMission, @v_tac_position
						SET @v_error = @@ERROR
						IF NOT (@v_status = @CODE_OK AND @v_error = 0)
							SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
						SET @v_ord_idordre = NULL
						SET @v_baseOrdreCourant = NULL
						SET @v_association = 1
						SET @v_baseTache = NULL
					END
					ELSE
					BEGIN
						SET @v_baseOrdreCourant = NULL
						SET @v_association = 0
						CONTINUE
					END
				END
				ELSE IF EXISTS (SELECT 1 FROM BASE WHERE BAS_BASE = @v_baseTache AND BAS_TYPE = 0)
				BEGIN
					SET @v_ord_position = CASE @v_association WHEN 1 THEN ISNULL(@v_ord_position, 0) + 1 ELSE ISNULL(@v_ord_position, 0) END
					EXEC @v_status = SPV_CREATEORDRE @v_ord_position, @v_idAgv, @v_idMission, @v_tac_position
					SET @v_error = @@ERROR
					IF NOT (@v_status = @CODE_OK AND @v_error = 0)
						SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
					SET @v_ord_idordre = NULL
					SET @v_baseOrdreCourant = NULL
					SET @v_association = 1
					SET @v_baseTache = NULL
					CONTINUE
				END
				ELSE IF @v_association = 1
				BEGIN
					SET @v_baseOrdreCourant = NULL
					SET @v_association = 0
					CONTINUE
				END
				SET @v_charindex = CHARINDEX(';', @v_lstBase)
				IF @v_charindex <> 0
				BEGIN
					-- Récupération de la base suivante dans la liste de bases
					SET @v_baseCourante = CONVERT(bigint, SUBSTRING(@v_lstBase, 1, @v_charindex - 1))
					SET @v_lstBase = SUBSTRING(@v_lstBase, @v_charindex + 1, LEN(@v_lstBase) - @v_charindex)
				END
			END
		END
		IF @v_status = @CODE_OK AND @v_error = 0
			SET @v_retour = @CODE_OK
	END
	IF @v_retour = @CODE_OK
		COMMIT TRAN
	ELSE
		ROLLBACK TRAN
	RETURN @v_retour

