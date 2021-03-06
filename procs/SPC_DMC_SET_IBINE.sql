SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Conversion des 2 mots automate en IDBobine
-- =============================================
CREATE PROCEDURE [dbo].[SPC_DMC_SET_IDBOBINE]
	@v_idBobine INT OUTPUT,
	@v_idBobineToChar1 VARCHAR(8),
	@v_idBobineToChar2 VARCHAR(8)
AS
BEGIN
-- Déclaration des constantes
DECLARE @CODE_OK INT

-- Déclaration des variables
DECLARE @Diviseur int,
		@IdBobineRestante bigint
DECLARE @Retour INT,
		@v_local INT,
		@v_transaction VARCHAR(50),
		@v_charIdBobine VARCHAR(16)

-- Initialisation des constantes
SET @CODE_OK = 0

-- Initialisation des variables
SET @Retour = @CODE_OK
SET @v_transaction = 'SPC_DMC_SET_IDBOBINE'

-- Calcul des 4 variables Automate
IF (@v_idBobineToChar2 = '0')
BEGIN
	SET @v_idBobine = CONVERT(INT, @v_idBobineToChar1)
END
ELSE
BEGIN
	SET @v_charIdBobine = CONCAT(@v_idBobineToChar1, @v_idBobineToChar2)
	SET @v_idBobine = CONVERT(INT, @v_charIdBobine)
END
END


