SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON

-- =============================================
-- Description:	Recherche le nombre d'emplacement vides d'une allée
-- @v_IdLaize : Identifiant Laize
-- @v_IdDiametre : Identifiant Diametre
-- @AdrSysAllee  : systeme de base d'execution
-- @AdrBaseAllee : systeme de base d'execution
-- @AdrSousBaseAllee  : systeme de base d'execution
-- =============================================
CREATE FUNCTION [dbo].[SPC_STK_GETEMPLACEMENTSVIDES]
(
	@IdLaize INT,
	@IdDiametre INT,
	@AdrSysAllee BIGINT,
	@AdrBaseAllee BIGINT,
	@AdrSousBaseAllee BIGINT
)
RETURNS SMALLINT
AS
BEGIN
-- Déclaration des variables
DECLARE @NbPlacesVides INT,
		@NbBobinesEnStock INT

declare @MaxBobines int
declare @EtatAllee INT
declare @MaxHauteur int
declare @NbProfondeur int
declare @NbMaxHauteur int
declare @MaxBobinesRecalcule int
declare @MaxNiveau INT
declare @Hauteur int
declare @chg_laizeTheorique int
declare @chg_diametre int

SELECT 
	@MaxBobines = (ADR_EMPLACEMENT_OCCUPE + dbo.SPC_STK_GETCAPACITE( @chg_laizeTheorique, @chg_diametre, @AdrSysAllee, @AdrBaseAllee, @AdrSousBaseAllee, @IdLaize ) ), --FST-0510-01 
	@NbBobinesEnStock = ADR_EMPLACEMENT_OCCUPE,
	@EtatAllee = ADR_IDETAT_OCCUPATION,
	@MaxHauteur = dbo.SPC_STK_GETNIVEAUMAXALLEE (@IdLaize, ADR_IDSYSTEME, ADR_IDBASE, ADR_IDSOUSBASE),
	@Hauteur = STR_HAUTEUR_COURANTE,
	@NbMaxHauteur = 
		(CASE @IdLaize	WHEN 1410 THEN NLH_NBPLEINELAIZE 
						WHEN 1286 THEN NLH_NBPLEINELAIZE  
						WHEN 1060 THEN NLH_NBTROISQUARTLAIZE
						WHEN 967  THEN NLH_NBTROISQUARTLAIZE
						WHEN 720  THEN NLH_NBDEMILAIZE
						WHEN 648  THEN NLH_NBDEMILAIZE
		 END)
FROM INT_ADRESSE
INNER JOIn STRUCTURE ON STR_SYSTEME = ADR_IDSYSTEME 
						AND STR_BASE = ADR_IDBASE 
						AND STR_SOUSBASE = ADR_IDSOUSBASE
INNER JOIN SPC_STK_NBLAIZEHAUTEUR ON ADR_IDSYSTEME = NLH_IDSYSTEME
									AND ADR_IDBASE = NLH_IDBASE
									AND ADR_IDSOUSBASE = NLH_IDSOUSBASE
WHERE ADR_IDSYSTEME = @AdrSysAllee
	AND ADR_IDBASE = @AdrBaseAllee
	AND ADR_IDSOUSBASE = @AdrSousBaseAllee

SET @MaxNiveau =
		(CASE @IdLaize	WHEN 1410 THEN 5 
						WHEN 1286 THEN 5  
						WHEN 1060 THEN 6
						WHEN 967  THEN 6
						WHEN 720  THEN 9
						WHEN 648  THEN 9
		 END)

IF @NbMaxHauteur > @MaxNiveau
	SET @NbMaxHauteur = @MaxNiveau

SET @NbProfondeur = @MaxBobines / @NbMaxHauteur
SET @MaxBobinesRecalcule = @NbMaxHauteur * @NbProfondeur

SET @NbPlacesVides = @MaxBobinesRecalcule - @NbBobinesEnStock

if @NbPlacesVides < 0
	set @NbPlacesVides = 0
	-- Return the result of the function
	RETURN @NbPlacesVides
END


