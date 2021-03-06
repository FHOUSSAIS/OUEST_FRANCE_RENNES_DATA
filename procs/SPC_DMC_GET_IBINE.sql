SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Conversion de l'IDBobine en 2 mots automate
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DMC_GET_IDBOBINE]
	@v_idBobine INT,
	@v_idBobineToChar1 VARCHAR(8) OUTPUT,
	@v_idBobineToChar2 VARCHAR(8) OUTPUT
AS
BEGIN
DECLARE @CODE_OK INT = 0
DECLARE	@CODE_KO INT = 1

DECLARE @retour INT = @CODE_OK
DECLARE @procStock VARCHAR(128) = OBJECT_NAME(@@PROCID)
DECLARE @moniteur VARCHAR(128) = 'Gestionnaire Demaculeuse'
DECLARE @trace VARCHAR(7500)
DECLARE @local INT = 0

DECLARE @idBobineToChar varchar(16)

	SET @v_idBobineToChar1 = SUBSTRING (CONVERT(VARCHAR, @v_idBobine), 1, 8)
	SET @v_idBobineToChar2 = ISNULL(SUBSTRING (CONVERT(VARCHAR, @v_idBobine), 9, 8), '0')

END


