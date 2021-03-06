SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procedure		: SPV_WRITEVARIABLEAUTOMATE
-- Paramètre d'entrée	: @v_type : Type
--			    0 : Entrée
--			    1 : Sortie
--			  @v_vau_id : Identifiant variable automate logique
--			  @v_vau_idinterface : Identifiant interface logique
--			  @v_vao_id : Identifiant variable automate physique
--			  @v_vao_idinterface : Identifiant interface physique
--			  @v_vau_valeur : Valeur
--			  @v_vao_qualite : Qualité
-- Paramètre de sortie	: Valeur de retour :
--			    @CODE_OK : Réussite
--			    @CODE_KO : Echec
--			    @CODE_KO_INCONNU : Variable inconnue
--			    @CODE_KO_SQL : Erreur SQL
-- Descriptif		: Ecriture des variables automates
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_WRITEVARIABLEAUTOMATE]
	@v_type bit,
	@v_vau_id int,
	@v_vau_idinterface int,
	@v_vao_id int,
	@v_vao_idinterface int,
	@v_vau_valeur varchar(8000),
	@v_vao_qualite tinyint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--Déclaration des variables
DECLARE
	@v_error int,
	@v_retour int,
	@v_count int

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
		SELECT @v_vau_id = VAU_ID FROM VARIABLE_AUTOMATE WHERE VAU_ID = (SELECT VAO_ID FROM VARIABLE_AUTOMATE_OPC WHERE VAO_ID = @v_vao_id AND VAO_INTERFACE = @v_vao_idinterface)
		IF @v_vau_id IS NOT NULL
		BEGIN
			UPDATE VARIABLE_AUTOMATE SET VAU_VALEUR = @v_vau_valeur, VAU_ALIRE = CASE @v_vao_qualite WHEN 192 THEN VAU_EVENT ELSE 0 END, VAU_DATE = GETDATE()
				WHERE VAU_ID = @v_vau_id AND (VAU_SENS = 'I' OR (VAU_SENS = 'IO' AND VAU_AECRIRE = 0)) AND VAU_VALEUR <> @v_vau_valeur
			SELECT @v_error = @@ERROR, @v_count = @@ROWCOUNT
			IF @v_error = 0
			BEGIN
				IF @v_count = 1 OR EXISTS (SELECT 1 FROM VARIABLE_AUTOMATE_OPC WHERE VAO_ID = @v_vao_id AND VAO_INTERFACE = @v_vao_idinterface AND VAO_QUALITE <> @v_vao_qualite)
				BEGIN
					UPDATE VARIABLE_AUTOMATE_OPC SET VAO_QUALITE = @v_vao_qualite WHERE VAO_ID = @v_vao_id
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
			SET @v_retour = @CODE_KO_INCONNU
	END
	ELSE IF @v_type = 1
	BEGIN
		IF EXISTS (SELECT 1 FROM VARIABLE_AUTOMATE WHERE VAU_ID = @v_vau_id AND VAU_IDINTERFACE = @v_vau_idinterface)
		BEGIN
			UPDATE VARIABLE_AUTOMATE SET VAU_VALEUR = @v_vau_valeur, VAU_AECRIRE = 1, VAU_DATE = GETDATE()
				WHERE VAU_ID = @v_vau_id  AND VAU_IDINTERFACE = @v_vau_idinterface
				AND VAU_SENS IN ('O', 'IO')
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


