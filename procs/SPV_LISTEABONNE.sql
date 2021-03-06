SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_LISTEABONNE
-- Paramètre d'entrée	: @v_mes_id : Message
-- Paramètre de sortie	: 
-- Descriptif		: Récupération de la liste des abonnés abonnés à un message
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_LISTEABONNE]
	@v_mes_id int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

IF EXISTS (SELECT 1 FROM MESSAGE WHERE MES_ID = @v_mes_id AND MES_ACTIF = 1)
	BEGIN
		SELECT ABO_ID FROM ABONNEMENT INNER JOIN ABONNE ON ABO_ID = ABN_ABONNE
			WHERE ABN_MESSAGE = @v_mes_id AND ABO_ON = 1 AND ABO_ID <> 7
		UNION
		SELECT 7 WHERE EXISTS (SELECT 1 FROM ABONNE WHERE ABO_ID = 7 AND ABO_ON = 1)
	END

