SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_READSEGMENT
-- Paramètre d'entrée	: @v_interface : Identifiant interface
-- Paramètre de sortie	: 
-- Descriptif		: Lecture des échanges de données entre bases de données
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_READSEGMENT]
	@v_interface int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

	SELECT SEG_ID, SEG_CONNEXION, SEG_DATA FROM SEGMENT LEFT OUTER JOIN CONNEXION ON CNX_ID = SEG_CONNEXION
		LEFT OUTER JOIN INTERFACE_SOCKET_TCPIP ON IST_ID = CNX_INTERFACE WHERE CNX_INTERFACE = @v_interface
		AND ((IST_TYPE = 0 AND CNX_ADDRESS IS NULL AND CNX_HOST IS NULL) OR (IST_TYPE = 1 AND ((CNX_ADDRESS IS NOT NULL) OR (CNX_HOST IS NOT NULL))))

