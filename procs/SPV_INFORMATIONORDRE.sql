SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF

-----------------------------------------------------------------------------------------
-- Procédure		: SPV_INFORMATIONORDRE
-- Paramètre d'entrée	: @v_ord_idordre : Identifiant de l'ordre
-- Paramètre de sortie	:
-- Descriptif		: Sélection des informations spécifiques liées à l'ordre à émettre
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_INFORMATIONORDRE]
	@v_ord_idordre int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- Déclaration des variables
DECLARE
	@v_par_valeur varchar(128)

	-- Récupération de la fonction d'évalution des conditions de gerbage
	SELECT @v_par_valeur = CASE PAR_VAL WHEN '' THEN NULL ELSE PAR_VAL END FROM PARAMETRE WHERE PAR_NOM = 'INFORMATIONORDRE'
	IF (@v_par_valeur IS NOT NULL)
		EXEC @v_par_valeur @v_ord_idordre
	ELSE
		SELECT NULL

