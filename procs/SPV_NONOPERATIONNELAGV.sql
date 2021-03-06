SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procedure		: SPV_NONOPERATIONNELAGV
-- Paramètre d'entrée	: @v_iag_idagv : Identifiant de l'Agv
-- Paramètre de sortie	: Code de retour par défaut
--			  - @CODE_OK : Le passage non opérationnel de l'Agv s'est exécutée correctement
--			  - @CODE_KO_SQL : Une erreur s'est produite lors du passage non opérationnel
-- Descriptif		: Cette procédure passe un Agv dans l'état NON OPERATIONNEL
--			  Si il existe un ordre en cours elle interrompt l'ordre agv en cours d'exécution.
--			  S'il existe des ordres en attente dont la description indique qu'il a été envoyé,
--			  cette information est supprimée.
--			  Elle met à jour l'état de l'Agv.
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_NONOPERATIONNELAGV]
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
	@v_ord_idordre int,
	@v_tac_idtache int,
	@v_tac_idordre int,
	@v_por_id int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE 
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_STOPPE tinyint,
	@ETAT_SUSPENDU tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_NON_OPERATIONNEL tinyint,
	@DESC_ANNULATION tinyint,
	@DESC_ENVOYE tinyint

-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_BATTERIE tinyint,
	@TYPE_MOUVEMENT tinyint

-- Déclaration des constantes d'action
DECLARE
	@ACTI_CONTROLE_FERMETURE_PORTE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_STOPPE = 3
	SET @ETAT_SUSPENDU = 4
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_NON_OPERATIONNEL = 6
	SET @DESC_ANNULATION = 9
	SET @DESC_ENVOYE = 13
	SET @TYPE_BATTERIE = 2
	SET @TYPE_MOUVEMENT = 3
	SET @ACTI_CONTROLE_FERMETURE_PORTE = 3

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	
	BEGIN TRAN
	-- Récupération de l'identifiant de l'ordre en cours
	SELECT TOP 1 @v_ord_idordre = ORD_IDORDRE FROM ORDRE_AGV
		WHERE ORD_IDAGV = @v_iag_idagv AND ((ORD_IDETAT = @ETAT_ENATTENTE AND ORD_DSCETAT = @DESC_ENVOYE) OR ORD_IDETAT = @ETAT_ENCOURS)
		ORDER BY ORD_POSITION
	IF @v_ord_idordre IS NOT NULL
	BEGIN
		-- Interruption de l'ordre en cours
		EXEC @v_status = SPV_INTERROMPTORDRE @v_ord_idordre, @DESC_NON_OPERATIONNEL
		SET @v_error = @@ERROR
	END
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM INT_MISSION_VIVANTE WHERE MIS_IDTYPEMISSION IN (@TYPE_MOUVEMENT, @TYPE_BATTERIE) AND MIS_IDAGV = @v_iag_idagv
			AND MIS_IDETATMISSION IN (@ETAT_ENATTENTE, @ETAT_STOPPE, @ETAT_SUSPENDU))
		BEGIN
			DECLARE c_tache CURSOR LOCAL FAST_FORWARD FOR SELECT TAC_IDTACHE, TAC_IDORDRE
				FROM INT_TACHE_MISSION WHERE TAC_IDMISSION IN (SELECT MIS_IDMISSION FROM INT_MISSION_VIVANTE WHERE MIS_IDTYPEMISSION IN (@TYPE_MOUVEMENT, @TYPE_BATTERIE) AND MIS_IDAGV = @v_iag_idagv
				AND MIS_IDETATMISSION IN (@ETAT_ENATTENTE, @ETAT_STOPPE, @ETAT_SUSPENDU)) AND TAC_IDETATTACHE NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
			OPEN c_tache
			FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_idordre
			WHILE ((@@FETCH_STATUS = 0) AND (@v_error = 0))
			BEGIN
				UPDATE TACHE SET TAC_IDETAT = @ETAT_ANNULE, TAC_DSCETAT = @DESC_ANNULATION, TAC_IDORDRE = NULL
					WHERE TAC_IDTACHE = @v_tac_idtache
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					IF @v_tac_idordre IS NOT NULL AND NOT EXISTS (SELECT 1 FROM INT_TACHE_MISSION WHERE TAC_IDORDRE = @v_tac_idordre)
					BEGIN
						UPDATE ORDRE_AGV SET ORD_IDETAT = @ETAT_ANNULE, ORD_DSCETAT = @DESC_ANNULATION
							WHERE ORD_IDORDRE = @v_tac_idordre
						SET @v_error = @@ERROR
					END
				END
				FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_idordre
			END
			CLOSE c_tache
			DEALLOCATE c_tache
		END
	END
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		UPDATE INFO_AGV SET IAG_ENCHARGE = 0, IAG_DECHARGE = CASE IAG_ENCHARGE WHEN 1 THEN 0 ELSE IAG_DECHARGE END, IAG_MAINTENANCE = 0
			WHERE IAG_ID = @v_iag_idagv
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			IF EXISTS (SELECT 1 FROM INFO_AGV WHERE IAG_ID = @v_iag_idagv AND IAG_CIRCUIT = 0)
			BEGIN
				EXEC @v_status = SPV_PORTE @v_action = @ACTI_CONTROLE_FERMETURE_PORTE, @v_agv = @v_iag_idagv
				SET @v_error = @@ERROR
			END
		END
	END
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		SET @v_retour = @CODE_OK
		COMMIT TRAN
	END
	ELSE
	BEGIN
		SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
		ROLLBACK TRAN
	END
	RETURN @v_retour


