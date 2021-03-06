SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_DEBUTEORDRE
-- Paramètre d'entrée	: @v_iag_id : Identifiant AGV
--			  @v_ord_idordre : Identifiant de l'ordre à débuter
--			  @v_type : Type
--			    0 : Mouvement
--			    1 : Action
--			  @v_iag_base_dest : Base de destination en cours
-- Paramètre de sortie	: Code de retour par défaut :
--			    - @CODE_OK : L'ordre a débuté correctement
--			    - @CODE_KO_INCONNU : L'ordre est inconnu
--			    - @CODE_KO_SQL : Une erreur s'est produite lors du lancement
-- Descriptif		: Cette procédure débute l'ordre initié sur l'AGV
--			  Le lancement d'un ordre le fait passer dans l'état en cours
--			  ainsi que la tâche qui lui est associée. La colonne IAG_BASE_DEST
--			  est mis à jour
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_DEBUTEORDRE]
	@v_iag_id tinyint,
	@v_ord_idordre int,
	@v_type bit,
	@v_iag_accostage_dest int,
	@v_iag_base_dest bigint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END
-- Déclaration des variables
DECLARE
	@v_retour smallint

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO_INCONNU tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes des états tâches et ordres
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint

-- Déclaration des constantes de descriptions
DECLARE
	@DESC_ENVOYE tinyint
	
-- Déclaration des constantes de types d'ordres
DECLARE
	@TYPE_MOUVEMENT bit,
	@TYPE_ACTION bit
	
-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_MAINTENANCE tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO_INCONNU = 7
	SET @CODE_KO_SQL = 13
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @DESC_ENVOYE = 13
	SET @TYPE_MOUVEMENT = 0
	SET @TYPE_ACTION = 1
	SET @TYPE_MAINTENANCE = 4

-- Initialisation de la variable de retour
	SET @v_retour = @CODE_OK

	BEGIN TRAN
	IF EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDORDRE = @v_ord_idordre AND ORD_IDETAT = @ETAT_ENATTENTE
		AND ORD_DSCETAT = @DESC_ENVOYE AND ORD_TYPE = @TYPE_MOUVEMENT)
	BEGIN
		-- Mise à jour des états des tâches et de la mission associée
		UPDATE TACHE SET TAC_IDETAT = @ETAT_ENCOURS, TAC_DSCETAT = NULL
			WHERE TAC_IDORDRE = @v_ord_idordre
		IF @@ERROR <> 0
			SET @v_retour = @CODE_KO_SQL
		ELSE
		BEGIN
			-- Mise à jour de l'état de l'ordre Agv
			UPDATE ORDRE_AGV SET ORD_IDETAT = @ETAT_ENCOURS, ORD_DSCETAT = NULL
				WHERE ORD_IDORDRE = @v_ord_idordre
			IF @@ERROR <> 0
				SET @v_retour = @CODE_KO_SQL
			ELSE
			BEGIN
				UPDATE INFO_AGV SET IAG_BASE_DEST = @v_iag_base_dest, IAG_BASE_ORIG = IAG_BASE_DEST, IAG_ACCOSTAGE_DEST = @v_iag_accostage_dest, IAG_ACCOSTAGE_ORIG = IAG_ACCOSTAGE_DEST,
					IAG_MAINTENANCE = (CASE WHEN EXISTS (SELECT 1 FROM TACHE INNER JOIN MISSION ON MIS_IDMISSION = TAC_IDMISSION
					WHERE TAC_IDORDRE = @v_ord_idordre AND MIS_TYPEMISSION = @TYPE_MAINTENANCE) THEN 1 ELSE 0 END)
					WHERE IAG_ID = @v_iag_id
				IF @@ERROR <> 0
					SET @v_retour = @CODE_KO_SQL
			END
		END
	END
	ELSE IF EXISTS (SELECT 1 FROM ORDRE_AGV WHERE ORD_IDORDRE = @v_ord_idordre AND ORD_IDETAT = @ETAT_ENCOURS
		AND ORD_TYPE = @TYPE_MOUVEMENT)
	BEGIN
		UPDATE ORDRE_AGV SET ORD_TYPE = @TYPE_ACTION WHERE ORD_IDORDRE = @v_ord_idordre
		IF @@ERROR <> 0
			SET @v_retour = @CODE_KO_SQL
	END
	ELSE
		SET @v_retour = @CODE_KO_INCONNU
	IF @v_retour <> @CODE_OK
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_retour



