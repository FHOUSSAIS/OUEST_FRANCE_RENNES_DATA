SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Recherche de l'état d'une allée de stockage
-- @v_IdLaize : Identifiant Laize
-- @v_IdDiametre : Identifiant Diametre
-- @AdrSysAllee  : systeme de base d'execution
-- @AdrBaseAllee : systeme de base d'execution
-- @AdrSousBaseAllee  : systeme de base d'execution
-- =============================================
CREATE FUNCTION [dbo].[SPC_STK_GETETATALLEE]
(
	@IdLaize INT,
	@IdDiametre INT,
	@AdrSysAllee BIGINT,
	@AdrBaseAllee BIGINT,
	@AdrSousBaseAllee BIGINT
)
RETURNS TINYINT
AS
BEGIN
-- Déclaration des constantes
DECLARE @ALLEE_OCCUPEE INT,
		@ALLEE_PLEINE INT

-- Initialisation des constantes
SET @ALLEE_OCCUPEE  = 2
SET @ALLEE_PLEINE	= 3

-- Déclaration des variables
DECLARE @EtatAllee INT
DECLARE @NbPlacesVides INT
DECLARE @EtatAlleeSTD INT

	-- Recherche du nombre d'emplacements vides
	EXEC  @NbPlacesVides = dbo.INT_GETCAPACITE @AdrSysAllee,@AdrBaseAllee,@AdrSousBaseAllee,1,0,@IdLaize,@IdDiametre,@IdDiametre,0,0
	SELECT @EtatAlleeSTD = ADR_IDETAT_OCCUPATION from INT_ADRESSE
		WHERE ADR_IDSYSTEME = @AdrSysAllee
			AND ADR_IDBASE = @AdrBaseAllee
			AND ADR_IDSOUSBASE = @AdrSousBaseAllee

	SET @EtatAllee = @EtatAlleeSTD
	IF @EtatAllee = @ALLEE_OCCUPEE
		AND @NbPlacesVides = 0
	BEGIN
		SET @EtatAllee = @ALLEE_PLEINE
	END

	-- Return the result of the function
	RETURN @EtatAllee
END

