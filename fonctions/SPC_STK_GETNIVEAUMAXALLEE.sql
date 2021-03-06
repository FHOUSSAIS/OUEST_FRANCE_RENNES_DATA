SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
-- =============================================
-- Description:	Calcul du niveau de dépose max autorisé dans une allée
-- @IdLaize : Identifiant de Laize
-- @AdrSysAllee  : systeme de base d'execution
-- @AdrBaseAllee : systeme de base d'execution
-- @AdrSousBaseAllee  : systeme de base d'execution
-- =============================================
CREATE FUNCTION [dbo].[SPC_STK_GETNIVEAUMAXALLEE]
(
	@IdLaize INT,
	@AdrSysAllee BIGINT,
	@AdrBaseAllee BIGINT,
	@AdrSousBaseAllee BIGINT
)
RETURNS SMALLINT
AS
BEGIN
	-- Déclaration des variables
	DECLARE @NiveauMaxAllee SMALLINT,
			@NbMaxHauteur INT,
			@HauteurLaize INT

	-- Recherche du niveau max associé à l'allée
	SELECT @NiveauMaxAllee = STRUCTURE.STR_HAUTEUR_COURANTE from STRUCTURE
		where STRUCTURE.STR_SYSTEME = @AdrSysAllee
			and STRUCTURE.STR_BASE = @AdrBaseAllee
			and STRUCTURE.STR_SOUSBASE = @AdrSousBaseAllee

	-- Retourne la valeur de gerbage calculée
	RETURN @NiveauMaxAllee
END

