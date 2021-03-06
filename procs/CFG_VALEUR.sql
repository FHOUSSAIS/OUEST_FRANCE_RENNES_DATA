SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: CFG_VALEUR
-- Paramètre d'entrées	: @v_val_entree : Identifiant entrée
--			  @v_val_sous_menu_contextuel : Identifiant sous-menu contextuel
--			  @v_val_information : Information
-- Paramètre de sorties	: @v_retour : Code de retour
-- Descriptif		: Gestion des valeurs des entrées
-----------------------------------------------------------------------------------------
-- Révision
-----------------------------------------------------------------------------------------
-- Date			: 30/09/2004
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 08/04/2005
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Mise à jour code de retour
-----------------------------------------------------------------------------------------
-- Date			: 05/04/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Finalisation du synoptique
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[CFG_VALEUR]
	@v_val_sous_menu_contextuel int,
	@v_val_entree int,
	@v_val_information varchar(32),
	@v_retour smallint out
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

DECLARE
	@v_error int

	BEGIN TRAN
	SELECT @v_retour = 113
	SELECT @v_error = 0
	UPDATE VALEUR SET VAL_INFORMATION = @v_val_information WHERE VAL_SOUS_MENU_CONTEXTUEL = @v_val_sous_menu_contextuel
		AND VAL_ENTREE = @v_val_entree
	SELECT @v_error = @@ERROR
	IF @v_error = 0
		SELECT @v_retour = 0
	IF @v_error <> 0
		ROLLBACK TRAN
	ELSE
		COMMIT TRAN
	RETURN @v_error

