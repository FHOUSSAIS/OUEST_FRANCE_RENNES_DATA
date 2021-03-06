SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

-- =============================================
-- Description:	Gestion de l'évaluation si la charge doit être gerbée ou non
-- @v_chg_idcharge_last : identifiant de la dernière charge
-- @v_chg_idcharge_next : identifiant de la prochaine charge
-- =============================================
CREATE FUNCTION [dbo].[SPC_CHG_EVAL_GERBAGE]
(
	@v_chg_idcharge_last int,
	@v_chg_idcharge_next int
)
RETURNS BIT
AS
BEGIN
-- Déclaration des constantes
DECLARE @GERBAGE_OK BIT
DECLARE @GERBAGE_AUSOL BIT

-- Déclaration des variables
DECLARE @GerbageBobine BIT
DECLARE @LaizeBobine SMALLINT,
		@DiametreBobine SMALLINT,
		@NiveauBobineEnStock SMALLINT
DECLARE @AdrSysAlleeStockage BIGINT,
		@AdrBaseAlleeStockage BIGINT,
		@AdrSousBaseAlleeStockage BIGINT,
		@HauteurMaxAlleeStockage INT,
		@NiveauMaxAlleeStockage SMALLINT	

-- Initialisation des constantes
SET @GERBAGE_OK		= 1
SET @GERBAGE_AUSOL	= 0

-- Initialisation des variables
SET @GerbageBobine = @GERBAGE_OK

IF @v_chg_idcharge_last = 0
BEGIN
	SET @GerbageBobine = @GERBAGE_OK
END
ELSE
BEGIN
	-- Recherche du lieu de stockage, du diamètre et de la laize de la dernière bobine stockée
	SELECT @LaizeBobine = CHG_HAUTEUR, @DiametreBobine = CHG_LARGEUR,
			@AdrSysAlleeStockage = CHG_IDSYSTEME,
			@AdrBaseAlleeStockage = CHG_IDBASE,
			@AdrSousBaseAlleeStockage = CHG_IDSOUSBASE,
			@HauteurMaxAlleeStockage = STR_HAUTEUR_COURANTE,
			@NiveauBobineEnStock = CHG_POSITIONNIVEAU
		FROM INT_CHARGE_VIVANTE
	LEFT OUTER JOIN SPC_ADRESSE_STOCK_GENERAL ON CHG_IDSYSTEME = SAG_IDSYSTEME
								AND CHG_IDBASE = SAG_IDBASE
								AND CHG_IDSOUSBASE = SAG_IDSOUSBASE
	INNER JOIN STRUCTURE ON CHG_IDSYSTEME = STR_SYSTEME
								AND CHG_IDBASE = STR_BASE
								AND CHG_IDSOUSBASE = STR_SOUSBASE							
	WHERE CHG_IDCHARGE = @v_chg_idcharge_last
	
	-- Pour toutes les allées du stock de masse et stock tampon
	-- Si le client a limité le nombre de bobines en hauteur et que celui ci est atteint
	-- => Forçage du gerbage au sol
	---------------------------------------------------------------------------------
	IF @GerbageBobine <> @GERBAGE_AUSOL
	BEGIN
		SET @NiveauMaxAlleeStockage = dbo.SPC_STK_GETNIVEAUMAXALLEE (@LaizeBobine, 
													@AdrSysAlleeStockage,
													@AdrBaseAlleeStockage,
													@AdrSousBaseAlleeStockage)
		-- Si le niveau de la dernière bobine en stock correspond au niveau max autorisé dans l'allée
		IF @NiveauBobineEnStock >= (@NiveauMaxAlleeStockage - @LaizeBobine)
		BEGIN
			SET @GerbageBobine = @GERBAGE_AUSOL
		END
	END
END	

-- Retourne la valeur de gerbage calculée
RETURN @GerbageBobine

END


