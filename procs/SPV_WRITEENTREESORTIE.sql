SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_WRITEENTREESORTIE
-- Paramètre d'entrée	: @v_type : Type
--			    0 : Entrée
--			    1 : Sortie
--			  @v_esl_id : Identifiant entrée/sortie logique
--			  @v_esl_idinterface : Identifiant interface logique
--			  @v_esp_id : Identifiant entrée/sortie physique
--			  @v_esp_idinterface : Identifiant interface physique
--			  @v_esl_valeur : Etat
--			  @v_esp_qualite : Qualité
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_INCONNU : Entrée/sortie inconnue
--			    @CODE_KO_SQL : Erreur SQL
-- Descriptif		: Ecriture des entrées/sorties
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_WRITEENTREESORTIE]
	@v_type bit,
	@v_esl_id int,
	@v_esl_idinterface int,
	@v_esp_id int,
	@v_esp_idinterface int,
	@v_esl_etat bit,
	@v_esp_qualite tinyint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_error int,	@v_retour int,	@v_count int

-- Déclaration des constantes de retour
DECLARE
	@CODE_OK int,
	@CODE_KO int,
	@CODE_KO_INCONNU int,
	@CODE_KO_SQL int

-- Définition des constantes
	SET @CODE_OK = 0
	SET @CODE_KO = 1
	SET @CODE_KO_INCONNU = 7
	SET @CODE_KO_SQL = 13

-- Initialisation de la variable de retour
	SET @v_error = 0
	SET @v_retour = @CODE_KO

	IF @v_type = 0
	BEGIN
		SELECT @v_esl_id = ESL_ID FROM ENTREE_SORTIE WHERE ESL_ID = (SELECT ESP_ID FROM ENTREE_SORTIE_OPC WHERE ESP_ID = @v_esp_id AND ESP_INTERFACE = @v_esp_idinterface)
		IF @v_esl_id IS NOT NULL
		BEGIN
			UPDATE ENTREE_SORTIE SET ESL_ETAT = @v_esl_etat, ESL_CHANGED = ESL_ALARM, ESL_DATE = GETDATE()
				WHERE ESL_ID = @v_esl_id AND ESL_SENS = 'I' AND ESL_ETAT <> @v_esl_etat
			SELECT @v_error = @@ERROR, @v_count = @@ROWCOUNT
			IF @v_error = 0
			BEGIN
				IF @v_count = 1 OR EXISTS (SELECT 1 FROM ENTREE_SORTIE_OPC WHERE ESP_ID = @v_esp_id AND ESP_INTERFACE = @v_esp_idinterface AND ESP_QUALITE <> @v_esp_qualite)
				BEGIN
					UPDATE ENTREE_SORTIE_OPC SET ESP_QUALITE = @v_esp_qualite WHERE ESP_ID = @v_esp_id
					SET @v_error = @@ERROR
					IF @v_error = 0
						SET @v_retour = @CODE_OK
					ELSE
						SET @v_retour = @CODE_KO_SQL
				END
				ELSE
					SET @v_retour = @CODE_OK
			END
		END
		ELSE
			SET @v_retour = @CODE_KO_INCONNU
	END
	ELSE IF @v_type = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM ENTREE_SORTIE WHERE ESL_ID = @v_esl_id AND ESL_INTERFACE = @v_esl_idinterface)
		BEGIN
			UPDATE ENTREE_SORTIE SET ESL_ETAT = @v_esl_etat, ESL_CHANGED = 1, ESL_DATE = GETDATE()
				WHERE ESL_ID = @v_esl_id AND ESL_INTERFACE = @v_esl_idinterface
				AND ESL_SENS = 'O'
			SET @v_error = @@ERROR
			IF @v_error = 0
				SET @v_retour = @CODE_OK
			ELSE
				SET @v_retour = @CODE_KO_SQL
		END
		ELSE
			SET @v_retour = @CODE_KO_INCONNU
	END
	RETURN @v_retour
