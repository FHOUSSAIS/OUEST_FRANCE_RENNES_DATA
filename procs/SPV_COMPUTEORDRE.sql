SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF






-----------------------------------------------------------------------------------------
-- Procedure		: SPV_COMPUTEORDRE
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant AGV
--			  @v_lstBase : Liste ordonnée de bases
-- Paramètre de sortie	: @v_ord_idordre : Identifiant ordre
--			  Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_SQL : Erreur SQL
-- Descriptif		: Ordonnancement et regroupement des ordres
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_COMPUTEORDRE]
	@v_iag_idagv tinyint,
	@v_lstBase varchar(8000),
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
	@v_retour int,
	@v_ord_idordre1 int,
	@v_ord_idordre2 int,
	@v_ord_position int,
	@v_tac_idtache int,
	@v_tac_idsystemeexecution bigint,
	@v_tac_idbaseexecution bigint,
	@v_tac_nombreaction tinyint,
	@v_charindex int,
	@v_adr_idbase bigint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@DESC_AFFINAGE_ADRESSE tinyint,
	@DESC_ENVOYE tinyint

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_EXECUTION tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @DESC_AFFINAGE_ADRESSE = 12
	SET @DESC_ENVOYE = 13
	SET @AFFI_EXECUTION = 2

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	BEGIN TRAN
	-- Récupération des ordres à ordonner et/ou regrouper
	DECLARE @v_ordre table (ORD_IDORDRE int NOT NULL, ORD_POSITION int NOT NULL)
	INSERT INTO @v_ordre SELECT DISTINCT ORD_IDORDRE, ORD_POSITION FROM ORDRE_AGV, TACHE A WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE AND A.TAC_IDORDRE = ORD_IDORDRE
		AND A.TAC_POSITION_TACHE = (SELECT MIN(B.TAC_POSITION_TACHE) FROM TACHE B WHERE B.TAC_IDMISSION = A.TAC_IDMISSION
		AND B.TAC_IDETAT = @ETAT_ENATTENTE)
	-- Traitement d'ordonnancement des ordres
	SELECT @v_ord_position = MAX(ORD_POSITION) FROM @v_ordre
	-- Mise à jour de la position des autres ordres
	UPDATE ORDRE_AGV SET ORD_POSITION = @v_ord_position - (SELECT COUNT(*) FROM ORDRE_AGV B WHERE B.ORD_IDAGV = @v_iag_idagv AND B.ORD_IDORDRE NOT IN (SELECT ORD_IDORDRE FROM @v_ordre)
		AND B.ORD_POSITION BETWEEN A.ORD_POSITION + 1 AND @v_ord_position - 1 AND B.ORD_IDETAT = @ETAT_ENATTENTE)
		FROM ORDRE_AGV A WHERE A.ORD_IDAGV = @v_iag_idagv AND A.ORD_IDORDRE NOT IN (SELECT ORD_IDORDRE FROM @v_ordre) AND A.ORD_IDETAT = @ETAT_ENATTENTE
		AND A.ORD_POSITION < @v_ord_position
	-- Mise à jour de la position des ordres à ordonner
	SELECT @v_ord_position = MIN(ORD_POSITION) FROM @v_ordre
	SET @v_charindex = CHARINDEX(';', @v_lstBase)
	WHILE ((@v_charindex <> 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
	BEGIN
		SET @v_adr_idbase = CONVERT(bigint, SUBSTRING(@v_lstBase, 1, @v_charindex - 1))
		SELECT TOP 1 @v_ord_idordre1 = TAC_IDORDRE FROM TACHE INNER JOIN ASSOCIATION_TACHE_ACTION_TACHE ON ATA_IDTACHE = TAC_IDTACHE INNER JOIN ACTION ON ACT_IDACTION = ATA_IDACTION, @v_ordre
			WHERE TAC_IDADRBASE = @v_adr_idbase AND ORD_IDORDRE = TAC_IDORDRE AND ATA_IDTYPEACTION = 0
			ORDER BY ACT_OCCUPATION DESC
		UPDATE ORDRE_AGV SET ORD_POSITION = @v_ord_position WHERE ORD_IDORDRE = @v_ord_idordre1
			AND ORD_POSITION <> @v_ord_position
		DELETE @v_ordre WHERE ORD_IDORDRE = @v_ord_idordre1
		SET @v_error = @@ERROR
		SET @v_ord_position = @v_ord_position + 1
		SET @v_lstBase = SUBSTRING(@v_lstBase, @v_charindex + 1, LEN(@v_lstBase) - @v_charindex)
		SET @v_charindex = CHARINDEX(';', @v_lstBase)
	END
	DELETE @v_ordre
	INSERT INTO @v_ordre SELECT ORD_IDORDRE, ORD_POSITION FROM ORDRE_AGV WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE
		AND NOT EXISTS (SELECT 1 FROM TACHE WHERE TAC_IDORDRE = ORD_IDORDRE AND TAC_AFFINAGEADR = @AFFI_EXECUTION AND TAC_IDAFFINAGEADRSYS IS NOT NULL
		AND TAC_IDAFFINAGEADRBASE IS NOT NULL AND TAC_IDAFFINAGEADRSSBASE IS NOT NULL)
	-- Traitement de regroupement des ordres
	DECLARE c_ordre CURSOR LOCAL SCROLL DYNAMIC FOR SELECT ORD_IDORDRE, ORD_POSITION FROM @v_ordre ORDER BY ORD_POSITION
	OPEN c_ordre
	FETCH NEXT FROM c_ordre INTO @v_ord_idordre1, @v_ord_position
	WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
	BEGIN
		SET @v_ord_idordre2 = NULL
		SELECT TOP 1 @v_tac_idtache = TAC_IDTACHE, @v_tac_idsystemeexecution = TAC_IDADRSYS, @v_tac_idbaseexecution = TAC_IDADRBASE,
			@v_tac_nombreaction = TAC_NBACTION FROM TACHE WHERE TAC_IDORDRE = @v_ord_idordre1
		SELECT TOP 1 @v_ord_idordre2 = ORD_IDORDRE FROM @v_ordre WHERE ORD_POSITION > @v_ord_position ORDER BY ORD_POSITION
		IF @v_ord_idordre2 IS NOT NULL
		BEGIN
			-- Comparaison de l'ordre n à l'ordre n + 1 en terme de base d'exécution, nombre d'actions
			-- types d'actions et options
			IF NOT EXISTS (SELECT 1 FROM ASSOCIATION_TACHE_ACTION_TACHE A
				WHERE A.ATA_IDTACHE = @v_tac_idtache AND NOT EXISTS (SELECT 1 FROM TACHE, ASSOCIATION_TACHE_ACTION_TACHE B
				WHERE TAC_IDORDRE = @v_ord_idordre2 AND B.ATA_IDTACHE = TAC_IDTACHE
				AND TAC_IDADRSYS = @v_tac_idsystemeexecution AND TAC_IDADRBASE = @v_tac_idbaseexecution
				AND TAC_NBACTION = @v_tac_nombreaction AND B.ATA_IDACTION = A.ATA_IDACTION AND B.ATA_IDTYPEACTION = A.ATA_IDTYPEACTION
				AND ISNULL(B.ATA_OPTION_ACTION, 0) = ISNULL(A.ATA_OPTION_ACTION, 0)))
			BEGIN
				-- Rattachement des tâches de l'ordre n + 1 à l'ordre n
				UPDATE TACHE SET TAC_IDORDRE = @v_ord_idordre1 WHERE TAC_IDORDRE = @v_ord_idordre2
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					EXEC @v_status = SPV_DELETEORDREAGV @v_ord_idordre2
					SET @v_error = @@ERROR
					IF @v_status = @CODE_OK AND @v_error = 0
					BEGIN
						UPDATE ORDRE_AGV SET ORD_POSITION = ORD_POSITION - 1 WHERE ORD_IDAGV = @v_iag_idagv
							AND ORD_POSITION >= @v_ord_position + 1
						SET @v_error = @@ERROR
						IF @v_error = 0
						BEGIN
							DELETE @v_ordre WHERE ORD_IDORDRE = @v_ord_idordre2
							FETCH FIRST FROM c_ordre INTO @v_ord_idordre1, @v_ord_position
						END
						ELSE
							SET @v_error = @CODE_KO_SQL
					END
					ELSE
						SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
				END
				ELSE
					SET @v_error = @CODE_KO_SQL
			END
			ELSE
				FETCH NEXT FROM c_ordre INTO @v_ord_idordre1, @v_ord_position
		END
		ELSE
			FETCH NEXT FROM c_ordre INTO @v_ord_idordre1, @v_ord_position
	END
	CLOSE c_ordre
	DEALLOCATE c_ordre
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		SELECT TOP 1 @v_ord_idordre = ORD_IDORDRE FROM ORDRE_AGV
			WHERE ORD_IDAGV = @v_iag_idagv AND ORD_IDETAT = @ETAT_ENATTENTE
			ORDER BY ORD_POSITION
		IF @v_ord_idordre IS NOT NULL
		BEGIN
			-- Recherche des adresses à affiner
			EXEC @v_status = SPV_AFFINEADRESSE 0, @v_iag_idagv, @v_ord_idordre
			SET @v_error = @@ERROR
			IF @v_status = @CODE_OK AND @v_error = 0
			BEGIN
				SET @v_retour = @CODE_OK
				COMMIT TRAN
			END
			ELSE
			BEGIN
				SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
				ROLLBACK TRAN
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
					EXEC @v_status = SPV_INTERROMPTORDRE @v_ord_idordre, @DESC_AFFINAGE_ADRESSE
					SET @v_error = @@ERROR
					IF NOT (@v_status = @CODE_OK AND @v_error = 0)
						ROLLBACK TRAN
					ELSE
						COMMIT TRAN
				END
			END
		END
		ELSE
		BEGIN
			SET @v_retour = @CODE_KO
			ROLLBACK TRAN
		END
	END
	ELSE
		ROLLBACK TRAN
	RETURN @v_retour

