SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_VUETABLEAU
-- Paramètre d'entrées	: @v_vta_couleur_ligne_impaire : Couleur d'une ligne impaire
--			  @v_vta_couleur_ligne_impaire : Couleur d'une ligne paire
--			  @v_vta_taille : Taille
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des vues tableaux
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Version/ révision	: 1.00
-- Date			: 20/09/2004
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Version/ révision	: 2.00
-- Date			: 08/04/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Mise à jour code de retour
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_VUETABLEAU]
	@v_vta_couleur_ligne_impaire int,
	@v_vta_couleur_ligne_paire int,
	@v_vta_taille tinyint,
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int,
	@v_old_vue_ordre tinyint

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	UPDATE VUE_TABLEAU SET VTA_COULEUR_LIGNE_IMPAIRE = @v_vta_couleur_ligne_impaire,
		VTA_COULEUR_LIGNE_PAIRE = @v_vta_couleur_ligne_paire, VTA_TAILLE = @v_vta_taille WHERE VTA_TYPE_VUE = 4
	SELECT @v_error = @@ERROR
	IF @v_error = 0
		SELECT @v_retour = 0
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

