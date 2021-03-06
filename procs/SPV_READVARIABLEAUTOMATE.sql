SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_READVARIABLEAUTOMATE
-- Paramètre d'entrée	: @v_type : Type
--			    0 : Entrée
--			    1 : Sortie
--			  @v_idinterface : Identifiant interface logique ou physique
-- Paramètre de sortie	: 
-- Descriptif		: Lecture des variables automates
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_READVARIABLEAUTOMATE]
	@v_type bit,
	@v_idinterface int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	IF @v_type = 0
	BEGIN
		SELECT VAU_ID, VAU_VALEUR FROM VARIABLE_AUTOMATE
			WHERE VAU_ALIRE = 1 AND VAU_EVENT = 1 AND VAU_SENS IN ('I', 'IO')
			AND VAU_IDINTERFACE = @v_idinterface AND ((DATEADD(second, VAU_DELAI, VAU_DATE) <= GETDATE() AND VAU_DELAI <> 0) OR (VAU_DELAI = 0))
		IF @@ROWCOUNT = 0
			SELECT MIN(DATEDIFF(second, GETDATE(), DATEADD(second, VAU_DELAI, VAU_DATE))) VAU_POOL FROM VARIABLE_AUTOMATE
				WHERE VAU_ALIRE = 1 AND VAU_EVENT = 1 AND VAU_SENS IN ('I', 'IO')
				AND VAU_IDINTERFACE = @v_idinterface AND VAU_DELAI <> 0
	END
	ELSE IF @v_type = 1
		SELECT VAO_ID, VAU_VALEUR FROM VARIABLE_AUTOMATE, VARIABLE_AUTOMATE_OPC
			WHERE VAU_AECRIRE = 1 AND VAU_SENS IN ('O', 'IO')
			AND VAO_INTERFACE = @v_idinterface AND VAO_ID = VAU_ID
			AND ((DATEADD(second, VAU_DELAI, VAU_DATE) <= GETDATE() AND VAU_DELAI <> 0) OR (VAU_DELAI = 0))


