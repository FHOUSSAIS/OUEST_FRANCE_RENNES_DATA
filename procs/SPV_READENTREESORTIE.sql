SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON





-----------------------------------------------------------------------------------------
-- Procédure		: SPV_READENTREESORTIE
-- Paramètre d'entrée	: @v_type : Type
--			    0 : Entrée
--			    1 : Sortie
--			  @v_idinterface : Interface
-- Paramètre de sortie	: 
-- Descriptif		: Lecture des entrées/sorties
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_READENTREESORTIE]
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
		SELECT ESL_ID, ESL_ETAT FROM ENTREE_SORTIE
			WHERE ESL_CHANGED = 1 AND ESL_ALARM = 1 AND ESL_SENS = 'I'
			AND ESL_INTERFACE = @v_idinterface AND ((DATEADD(second, ESL_DELAI, ESL_DATE) <= GETDATE() AND ESL_DELAI <> 0) OR (ESL_DELAI = 0))
		IF @@ROWCOUNT = 0
			SELECT MIN(DATEDIFF(second, GETDATE(), DATEADD(second, ESL_DELAI, ESL_DATE))) ESL_POOL FROM ENTREE_SORTIE
				WHERE ESL_CHANGED = 1 AND ESL_ALARM = 1 AND ESL_SENS = 'I'
				AND ESL_INTERFACE = @v_idinterface AND ESL_DELAI <> 0
	END
	ELSE IF @v_type = 1
		SELECT ESP_ID, ESP_CODE, ESL_ETAT FROM ENTREE_SORTIE_OPC INNER JOIN ENTREE_SORTIE ON ESL_ID = ESP_ID
			WHERE ESL_CHANGED = 1 AND ESL_SENS = 'O' AND ESP_INTERFACE = @v_idinterface
			AND ((DATEADD(second, ESL_DELAI, ESL_DATE) <= GETDATE() AND ESL_DELAI <> 0) OR (ESL_DELAI = 0))

