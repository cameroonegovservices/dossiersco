require 'test_helper'

class DossierEleveTest < ActiveSupport::TestCase

  test "a une fabrique valide" do
    assert Fabricate.build(:dossier_eleve).valid?
  end

  test "donne la liste des pièces jointes vierges" do
    etablissement = Fabricate(:etablissement)
    piece_attendue = Fabricate(:piece_attendue, etablissement: etablissement)
    dossier_eleve = Fabricate(:dossier_eleve, etablissement: etablissement)

    assert_equal 1, dossier_eleve.pieces_jointes.count
    assert_nil dossier_eleve.pieces_jointes[0].id
    assert_equal piece_attendue, dossier_eleve.pieces_jointes[0].piece_attendue
  end

  test "donne la liste avec la pièce jointe" do
    etablissement = Fabricate(:etablissement)
    piece_attendue = Fabricate(:piece_attendue, etablissement: etablissement)
    dossier_eleve = Fabricate(:dossier_eleve, etablissement: etablissement)
    piece_jointe = Fabricate(:piece_jointe, dossier_eleve: dossier_eleve, piece_attendue: piece_attendue)

    assert_equal 1, dossier_eleve.pieces_jointes.count
    assert_equal piece_jointe, dossier_eleve.pieces_jointes[0]
    assert_equal piece_attendue, dossier_eleve.pieces_jointes[0].piece_attendue
  end
end

