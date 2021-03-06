SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON





-----------------------------------------------------------------------------------------
-- Procédure		: SPV_CREATEORDRE
-- Paramètre d'entrée	: @v_position_Ordre : Position de l'ordre dans la liste des ordres Agv
--			  @v_idAgv : Identifiant de l'Agv
--			  @v_idMission : Identifiant de la mission à laquelle est rattaché l'ordre Agv
--			  @v_position_Tache : Position de la tâche de l'ordre dans la mission
-- Paramètre de sortie	: Code de retour par défaut :
--			  - @CODE_OK : l'ordre a été correctement créé.
--			  - @CODE_KO_SQL : Une erreur s'est produite lors de la création de l'ordre. 
--			  - @CODE_KO_INCOMPATIBLE : La mission n'est pas compatible avec les capacités physiques des outils
--			  @v_idOrdre : Identifiant de l'ordre Agv créé
-- Descriptif		: Cette procédure crée un nouvel ordre Agv
--			  - Incrémente de 1 la position des ordres Agv dont la position est
--			  > ou =  à @v_position.
--			  - Création du nouvel ordre dans la table ORDRE_AGV
--			  - Création du lien entre l'ordre Agv et la tâche en base de données.
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_CREATEORDRE]
	@v_position_Ordre integer,
	@v_idAgv tinyint,
	@v_idMission integer,
	@v_position_Tache tinyint
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
	@v_ord_idordre int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK tinyint,
	@CODE_KO tinyint,
	@CODE_KO_SQL tinyint,
	@CODE_KO_INCOMPATIBLE tinyint

-- Déclaration des constantes d'états et descriptions
DECLARE
	@ETAT_ENATTENTE tinyint

-- Déclaration des constantes de types d'ordres
DECLARE
	@TYPE_MOUVEMENT bit

-- Déclaration des constantes de type d'affinage
DECLARE
	@AFFI_EXECUTION tinyint	

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_SQL = 13
	SET @CODE_KO_INCOMPATIBLE = 14
	SET @ETAT_ENATTENTE = 1
	SET @TYPE_MOUVEMENT = 0
	SET @AFFI_EXECUTION = 2

-- Initialisation des variables
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	-- Refus si la l'ordre est à réaliser au delà de la première profondeur
	IF NOT EXISTS (SELECT 1 FROM TACHE INNER JOIN ADRESSE ON ADR_SYSTEME = TAC_IDADRSYS AND ADR_BASE = TAC_IDADRBASE AND ADR_SOUSBASE = TAC_IDADRSSBASE
		INNER JOIN BASE ON BAS_SYSTEME = ADR_SYSTEME AND BAS_BASE = ADR_BASE
		WHERE TAC_IDMISSION = @v_idMission AND TAC_POSITION_TACHE = @v_position_Tache
		AND TAC_AFFINAGEADR <> @AFFI_EXECUTION AND BAS_TYPE = 1 AND ADR_PROFONDEUR > 1)
	BEGIN
		-- Incrémentations des positions des ordres Agv.
		update ORDRE_AGV set ORD_Position = ORD_Position + 1 
			where ORD_POSITION >= @v_position_Ordre AND ORD_IdAgv = @v_idAgv
		SET @v_error = @@ERROR
		IF @v_error = 0
		BEGIN
			-- Insertion d'un ordre Agv. 
			INSERT INTO ORDRE_AGV (ORD_IDAGV, ORD_POSITION, ORD_IDETAT, ORD_TYPE)
				VALUES (@v_idAgv, @v_position_Ordre, @ETAT_ENATTENTE, @TYPE_MOUVEMENT)
			SET @v_error = @@ERROR
			IF @v_error = 0
			BEGIN
				-- Récupération de l'identifiant d'ordre Agv
				SET @v_ord_idordre = SCOPE_IDENTITY()
				-- Mise à jour du lien entre la tâche et l'ordre Agv
				update TACHE set TAC_IdOrdre = @v_ord_idordre
					where TAC_IdMission = @v_idMission and TAC_Position_Tache = @v_position_Tache
				SET @v_error = @@ERROR
				IF @v_error <> 0
					SET @v_retour = @CODE_KO_SQL
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
		SET @v_retour = @CODE_KO_INCOMPATIBLE
	
	RETURN @v_retour


