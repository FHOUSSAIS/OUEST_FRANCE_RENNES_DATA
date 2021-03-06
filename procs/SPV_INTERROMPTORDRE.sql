SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

-----------------------------------------------------------------------------------------
-- Procedure		: SPV_INTERROMPTORDRE
-- Paramètre d'entrée	: @v_ord_idordre : Identifiant ordre
--			  @v_interruption : Cause de l'interruption :
--			    - suite à une initialisation Agv
--			    - suite à une mise hors service Agv
-- Paramètre de sortie	: Code de retour par défaut
--			    - @CODE_OK : L'interruption d'ordre s'est exécutée correctement
--			    - @CODE_KO_SQL : Une erreur s'est produite lors de l'interruption
-- Descriptif		: Interruption d'un ordre en cours d'exécution et vérification
--			  de la validité des ordres suivants
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_INTERROMPTORDRE]
	@v_ord_idordre int,
	@v_interruption tinyint
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
	@v_iag_idagv tinyint,
	@v_tac_idtache int,
	@v_tac_idmission int,
	@v_chg_idcharge int,
	@v_mis_idtypemission tinyint,
	@v_ord_idetatordre tinyint,
	@v_tac_idetattache tinyint,
	@v_tac_descriptionetat tinyint,
	@v_ord_idordresuivant int,
	@v_ord_position int,
	@v_ord_positionsuivant int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint,
	@ETAT_ENCOURS tinyint,
	@ETAT_SUSPENDU tinyint,
	@ETAT_STOPPE tinyint,
	@ETAT_TERMINE tinyint,
	@ETAT_ANNULE tinyint,
	@DESC_AFFINAGE_ADRESSE tinyint,
	@DESC_AFFINAGE_TACHE tinyint

-- Déclaration des constantes de types de missions
DECLARE
	@TYPE_TRANSFERT_CHARGE tinyint,
	@TYPE_MAINTENANCE tinyint

-- Déclaration des constantes de types de magasin
DECLARE
	@TYPE_AGV tinyint

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @ETAT_ENATTENTE = 1
	SET @ETAT_ENCOURS = 2
	SET @ETAT_STOPPE = 3
	SET @ETAT_SUSPENDU	 = 4
	SET @ETAT_TERMINE = 5
	SET @ETAT_ANNULE = 6
	SET @DESC_AFFINAGE_ADRESSE = 12
	SET @DESC_AFFINAGE_TACHE = 15
	SET @TYPE_TRANSFERT_CHARGE = 1
	SET @TYPE_MAINTENANCE = 4
	SET @TYPE_AGV = 1

-- Initialisation des variables
	SET @v_error = 0
	SET @v_status = @CODE_OK
	SET @v_retour = @CODE_KO

	SET @v_ord_idetatordre = @ETAT_ANNULE
	-- Récupération des tâches à interrompre
	DECLARE c_tache CURSOR LOCAL FOR SELECT TAC_IDTACHE, TAC_IDMISSION, MIS_IDCHARGE, MIS_TYPEMISSION, ORD_POSITION, ORD_IDAGV
		FROM ORDRE_AGV INNER JOIN TACHE ON TAC_IDORDRE = ORD_IDORDRE INNER JOIN MISSION ON TAC_IDMISSION = MIS_IDMISSION INNER JOIN INFO_AGV ON IAG_ID = ORD_IDAGV
		WHERE ORD_IDORDRE = @v_ord_idordre FOR UPDATE
	OPEN c_tache
	FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_idmission, @v_chg_idcharge, @v_mis_idtypemission, @v_ord_position, @v_iag_idagv
	WHILE ((@@FETCH_STATUS = 0) AND (@v_status = @CODE_OK) AND (@v_error = 0))
	BEGIN
		SET @v_tac_idetattache = @ETAT_ANNULE
		SET @v_tac_descriptionetat = @v_interruption
		IF @v_mis_idtypemission = @TYPE_MAINTENANCE
			SET @v_tac_idetattache = @ETAT_ENATTENTE
		ELSE IF @v_mis_idtypemission = @TYPE_TRANSFERT_CHARGE
		BEGIN
			IF EXISTS (SELECT 1 FROM CHARGE LEFT OUTER JOIN ADRESSE ON ADR_SYSTEME = CHG_ADR_KEYSYS AND ADR_BASE = CHG_ADR_KEYBASE
				AND ADR_SOUSBASE = CHG_ADR_KEYSSBASE LEFT OUTER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE
				WHERE CHG_ID = @v_chg_idcharge AND BAS_TYPE_MAGASIN = @TYPE_AGV AND BAS_MAGASIN = @v_iag_idagv)
			BEGIN
				SET @v_ord_idetatordre = @ETAT_STOPPE
				SET @v_tac_idetattache = @ETAT_STOPPE
			END
			ELSE
				IF @v_interruption IN (@DESC_AFFINAGE_ADRESSE, @DESC_AFFINAGE_TACHE)
					SET @v_tac_idetattache = @ETAT_SUSPENDU
				ELSE
					SET @v_tac_idetattache = @ETAT_ENATTENTE
		END
		IF @v_error = 0
		BEGIN
			-- Dans le cas d'une tâche qui repasse en attente ou suspendu, les autres tâches terminées ou annulées de la mission
			-- repasse également en attente ou suspendu
	  		IF @v_tac_idetattache IN (@ETAT_ENATTENTE, @ETAT_SUSPENDU)
			BEGIN
				UPDATE TACHE SET TAC_IDETAT = @v_tac_idetattache, TAC_DSCETAT = @v_tac_descriptionetat
					WHERE TAC_IDTACHE <> @v_tac_idtache AND TAC_IDMISSION = @v_tac_idmission
					AND TAC_IDETAT IN (@ETAT_TERMINE, @ETAT_ANNULE)
				SET @v_error = @@ERROR
			END
			IF @v_error = 0
			BEGIN
				-- Mise à jour de l'état de la tâche et de la mission puis suppression du rattachement à l'ordre
				-- quand la tâche repasse dans l'état attente ou annulé
				UPDATE TACHE SET TAC_IDETAT = @v_tac_idetattache, TAC_DSCETAT = @v_tac_descriptionetat,
					TAC_IDORDRE = CASE @v_tac_idetattache WHEN @ETAT_STOPPE THEN @v_ord_idordre ELSE NULL END
					WHERE CURRENT OF c_tache
				SET @v_error = @@ERROR
				IF @v_error = 0
				BEGIN
					IF ((@v_tac_idetattache = @ETAT_STOPPE AND @v_interruption NOT IN (@DESC_AFFINAGE_ADRESSE, @DESC_AFFINAGE_TACHE)) OR (@v_tac_idetattache = @ETAT_ENATTENTE))
					BEGIN
						EXEC @v_status = SPV_DESAFFINEEXECUTION @v_tac_idmission
						SET @v_error = @@ERROR
						IF NOT (@v_status = @CODE_OK AND @v_error = 0)
							SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END
					END
				END
				ELSE
					SET @v_retour = @CODE_KO_SQL
			END
			ELSE
				SET @v_retour = @CODE_KO_SQL
		END
		ELSE
			SET @v_retour = @CODE_KO_SQL
		FETCH NEXT FROM c_tache INTO @v_tac_idtache, @v_tac_idmission, @v_chg_idcharge, @v_mis_idtypemission, @v_ord_position, @v_iag_idagv
	END
	CLOSE c_tache
	DEALLOCATE c_tache
	IF @v_status = @CODE_OK AND @v_error = 0
	BEGIN
		-- Récupération de l'ordre suivant
		SELECT TOP 1 @v_ord_idordresuivant = ORD_IDORDRE, @v_ord_positionsuivant = ORD_POSITION FROM ORDRE_AGV
			WHERE ORD_IDAGV = @v_iag_idagv AND ORD_POSITION > @v_ord_position AND ORD_IDETAT NOT IN (@ETAT_TERMINE, @ETAT_ANNULE)
			ORDER BY ORD_POSITION
		-- Mise à jour de l'état de l'ordre
		UPDATE ORDRE_AGV SET ORD_IDETAT = @v_ord_idetatordre, ORD_DSCETAT = @v_interruption
			WHERE ORD_IDORDRE = @v_ord_idordre
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			-- Traitement des ordres suivants
			IF @v_ord_idordresuivant IS NOT NULL
			BEGIN
				EXEC @v_status = SPV_REVISEORDRE @v_ord_idordresuivant, @v_iag_idagv, @v_ord_positionsuivant, 1
				SET @v_error = @@ERROR
				IF @v_status = @CODE_OK AND @v_error = 0
					SET @v_retour = @CODE_OK
				ELSE
					SET @v_retour = CASE @v_status WHEN @CODE_OK THEN @v_error ELSE @v_status END	
			END
			ELSE
				SET @v_retour = @CODE_OK
		END
		ELSE
			SET @v_retour = @CODE_KO_SQL
	END
	RETURN @v_retour


